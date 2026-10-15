class Api::SessionsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token

  PERMISSION_KEYS = %i[
    can_create_users can_create_orders can_modify_orders can_import_quote can_generic_order
    can_view_dashboard can_view_analysis can_view_market_indices can_view_intelligence_buying
    can_view_nomenclature
  ].freeze

  def me
    if current_user
      preview = preview_profile
      perms = if preview
        # Mode test : uniquement les droits du profil simulé, jamais ceux de l'administrateur.
        granted = User::PREVIEW_PROFILES.fetch(preview)[:perms]
        PERMISSION_KEYS.index_with { |k| granted.fetch(k, false) }
      else
        PERMISSION_KEYS.index_with { |k| current_user.public_send("effective_#{k}?") }
      end
      render json: perms.merge(
        logged_in:         true,
        admin:             preview ? false : current_user.admin?,
        preview_profile:   preview,
        preview_label:     preview && User::PREVIEW_PROFILES.fetch(preview)[:label],
        full_name:         current_user.full_name,
        email:             current_user.email,
        phone:             current_user.phone,
        sector:            current_user.sector,
        # Date réelle de la dernière modification d'un article (tarif, prix…),
        # et non la date du fichier catalogue.html (= date du dernier déploiement).
        catalogLastUpdated: (Product.maximum(:updated_at) || File.mtime(Rails.root.join("public/catalogue.html"))).strftime("%d.%m.%Y"),
        vapidPublicKey:    Rails.application.config.x.vapid_public_key,
        pushSubscribed:    current_user.push_subscriptions.exists?,
        supplierEmailsByCanton: Supplier.all.each_with_object({}) { |s, h|
          per_canton = Supplier::CANTONS.each_with_object({}) { |c, ch|
            email = s.public_send("email_#{c.downcase}")
            ch[c] = email if email.present?
          }
          h[s.name] = per_canton if per_canton.any?
        },
        # E-mail par défaut réellement configuré sur la fiche fournisseur
        # (Admin > Fournisseurs) — le client ne doit jamais retomber sur une
        # adresse figée dans catalogue.html si celle-ci existe.
        supplierDefaultEmails: Supplier.where.not(email: [ nil, "" ]).pluck(:name, :email).to_h,
        allowed_suppliers: current_user.effective_visible_suppliers,
        chantiers:         Chantier.visible_to(current_user).order(:nom).map { |c|
          {
            nom:         c.nom,
            adresse:     c.adresse,
            npa:         c.npa,
            ville:       c.ville,
            contact:     c.contremaitre,
            telephone:   c.natel_contremaitre,
            contactLivraison:   c.contact_livraison,
            telephoneLivraison: c.natel_livraison,
            emailTechnicien: c.email_technicien,
            consortium:  c.consortium,
            canton:      c.canton
          }
        }
      )
    else
      render json: { logged_in: false, admin: false, allowed_suppliers: [] }
    end
  end
end
