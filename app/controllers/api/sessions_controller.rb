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
        can_view_nomenclature: current_user.effective_can_view_nomenclature?,
        vapidPublicKey:    Rails.application.config.x.vapid_public_key,
        pushSubscribed:    current_user.push_subscriptions.exists?,
        allowed_suppliers: current_user.allowed_suppliers,
        chantiers:         Chantier.visible_to(current_user).order(:nom).map { |c|
          {
            nom:         c.nom,
            adresse:     c.adresse,
            npa:         c.npa,
            ville:       c.ville,
            contact:     c.contremaitre,
            telephone:   c.natel_contremaitre,
            emailTechnicien: c.email_technicien,
            consortium:  c.consortium
          }
        }
      }
    else
      render json: { logged_in: false, admin: false, allowed_suppliers: [] }
    end
  end
end
