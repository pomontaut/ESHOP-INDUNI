class Api::SessionsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token

  def me
    if current_user
      render json: {
        logged_in:         true,
        admin:             current_user.admin?,
        full_name:         current_user.full_name,
        sector:            current_user.sector,
        can_create_users:  current_user.effective_can_create_users?,
        can_create_orders: current_user.effective_can_create_orders?,
        can_modify_orders: current_user.effective_can_modify_orders?,
        can_import_quote:  current_user.effective_can_import_quote?,
        can_generic_order: current_user.effective_can_generic_order?,
        can_view_dashboard:    current_user.effective_can_view_dashboard?,
        can_view_analysis:     current_user.effective_can_view_analysis?,
        can_view_market_indices:      current_user.effective_can_view_market_indices?,
        can_view_intelligence_buying: current_user.effective_can_view_intelligence_buying?,
        can_view_nomenclature: current_user.effective_can_view_nomenclature?,
        catalogLastUpdated: File.mtime(Rails.root.join("public/catalogue.html")).strftime("%d.%m.%Y"),
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
            emailTechnicien: c.email_technicien,
            consortium:  c.consortium,
            canton:      c.canton
          }
        }
      }
    else
      render json: { logged_in: false, admin: false, allowed_suppliers: [] }
    end
  end
end
