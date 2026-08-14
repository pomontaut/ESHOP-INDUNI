class GenericOrdersController < ApplicationController
  FORM_PATH = Rails.root.join("app/views/generic_orders/form.html")

  before_action :require_generic_order_permission

  def show
    render html: File.read(FORM_PATH).html_safe, layout: false
  end

  private

  def require_generic_order_permission
    unless current_user&.effective_can_generic_order?
      redirect_to root_path, alert: "Accès réservé — vous n'avez pas accès au module Bon de commande générique."
    end
  end
end
