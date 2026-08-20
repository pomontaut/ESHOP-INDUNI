class Api::ProductsController < ApplicationController
  # Le catalogue complet (prix, fournisseurs) ne doit jamais être accessible
  # sans connexion, et un utilisateur ne doit voir que les fournisseurs que
  # son secteur/canton et ses éventuelles restrictions manuelles autorisent
  # (voir User#effective_visible_suppliers et /admin/contrats).
  def index
    visible = current_user.effective_visible_suppliers
    products = Product.joins(:supplier).includes(:supplier)
      .where.not(famille: nil)
      .where(suppliers: { name: visible })
      .order(:id)
    render json: products.map { |p|
      {
        catalog:          p.supplier&.name,
        article:          p.reference,
        designation:      p.name,
        descriptif:       p.descriptif,
        prix:             p.unit_price.to_f,
        unite:            p.unite,
        famille:          p.famille,
        sousFamille:      p.sous_famille,
        sousSousFamille:  p.sous_sous_famille,
        icone:            p.icone,
        image:            p.image,
        equivalenceKey:   p.equivalence_key,
        qtePalette:       p.qte_palette,
        poids:            p.poids_kg&.to_f,
        prixM2:           p.prix_m2&.to_f
      }
    }
  end
end
