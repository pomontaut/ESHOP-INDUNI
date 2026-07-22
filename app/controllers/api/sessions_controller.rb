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
        allowed_suppliers: current_user.allowed_suppliers,
        chantiers:         Chantier.visible_to(current_user).order(:nom).map { |c|
          {
            nom:         c.nom,
            adresse:     c.adresse,
            npa:         c.npa,
            ville:       c.ville,
            contact:     c.contremaitre,
            telephone:   c.natel_contremaitre
          }
        }
      }
    else
      render json: { logged_in: false, admin: false, allowed_suppliers: [] }
    end
  end
end
