class Api::ProductsController < ApplicationController
  # Le catalogue complet (prix, fournisseurs) ne doit jamais être accessible
  # sans connexion, et un utilisateur ne doit voir que les fournisseurs que
  # son secteur/canton et ses éventuelles restrictions manuelles autorisent
  # (voir User#effective_visible_suppliers et /admin/contrats).
  def index
    visible = current_user.effective_visible_suppliers
    # E-shops en cours de développement : réservés au mode Développement admin.
    dev_mode = Api::TestProfilesController.dev_mode?(session, current_user)
    visible -= Supplier::TEST_ONLY_NAMES unless dev_mode
    products = Product.joins(:supplier).includes(:supplier)
      .where.not(famille: nil)
      .where(suppliers: { name: visible })
      # Décision Achats : seule la famille Isolation de Swisspor est ouverte
      # à la commande pour l'instant. Le reste du catalogue Swisspor (déjà
      # tarifé) est gardé en base, masqué ici plutôt que supprimé, le temps
      # qu'il soit éventuellement réactivé.
      .where.not("suppliers.name = ? AND products.famille != ?", "Swisspor", "Isolation")
      .order(:id)
    # Nomenclature Induni : n° et désignation INDUNI de l'article (sans prix),
    # affichés en petit sur les fiches ; ces deux champs et les mots clefs d'aide à la recherche
    # (induniKeywords) alimentent la recherche.
    induni = NomenclatureEntry.all.index_by { |e| [ e.supplier_name, e.supplier_reference ] }
    memory_kw = SearchMemory.keywords_by_product # mots clefs appris par l'agent « moteur de recherche »
    render json: products.map { |p|
      confidential = p.supplier&.confidential_pricing?
      {
        catalog:          p.supplier&.name,
        article:          p.reference,
        designation:      p.name,
        descriptif:       p.descriptif,
        # Prix net confidentiel (ex. accord fournisseur marqué CONFIDENTIAL) :
        # jamais envoyé au navigateur en dehors de l'Analyse achat, où il est
        # reconstitué côté serveur à partir des commandes réellement passées
        # (voir Api::OrdersController#index et #create) — pas depuis ce endpoint.
        prix:             confidential ? 0 : p.unit_price.to_f,
        confidential:     confidential,
        unite:            p.unite,
        famille:          p.famille,
        sousFamille:      p.sous_famille,
        sousSousFamille:  p.sous_sous_famille,
        icone:            p.icone,
        image:            visible_image(p.image, dev_mode),
        ficheUrl:         p.fiche_url,
        equivalenceKey:   p.equivalence_key,
        qtePalette:       p.qte_palette,
        stockStatus:      p.stock_status,
        poids:            p.poids_kg&.to_f,
        prixM2:           p.prix_m2&.to_f,
        prixExterne:      p.prix_externe&.to_f,
        induniReference:  induni[[ p.supplier&.name, p.reference ]]&.induni_reference,
        induniDesignation: induni[[ p.supplier&.name, p.reference ]]&.induni_designation,
        induniKeywords:   [ induni[[ p.supplier&.name, p.reference ]]&.search_keywords, memory_kw[[ p.supplier&.name, p.reference ]] ].compact_blank.join(" ; ").presence
      }
    }
  end

  private

  # Photos web (« web-<n° article>.jpg », trouvées chez des fabricants/revendeurs,
  # voir docs/photos_materiel_induni_web.md) : en essai, donc masquées hors du
  # mode Développement (environnement test).
  WEB_PHOTO_PREFIX = "/images/products/web-".freeze
  # Photos HILTI (« hilti-<fichier hilti.ch>.jpg », récupérées sur la recherche de
  # hilti.ch par n° d'article exact) : également en essai, masquées hors mode
  # Développement. L'ancienne photo 2238557 (hilti-2238557.jpg) reste visible.
  HILTI_PHOTO_PREFIX = "/images/products/hilti-".freeze
  HILTI_PHOTO_PUBLIC = ["/images/products/hilti-2238557.jpg"].freeze

  def visible_image(image, dev_mode)
    return image if dev_mode || image.blank?
    return nil if image.start_with?(WEB_PHOTO_PREFIX)
    return nil if image.start_with?(HILTI_PHOTO_PREFIX) && !HILTI_PHOTO_PUBLIC.include?(image)
    image
  end
end
