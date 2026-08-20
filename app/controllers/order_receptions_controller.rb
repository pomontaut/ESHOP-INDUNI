class OrderReceptionsController < ApplicationController
  skip_before_action :require_login

  before_action :load_order

  def show
  end

  def confirm
    unless @order.reception_confirmed?
      @order.update!(reception_confirmed_at: Time.current)
      OrderMailer.reception_confirmed(@order).deliver_now rescue nil
    end
    render :show
  end

  private

  def load_order
    @order = Order.find_by!(reception_token: params[:token])
  rescue ActiveRecord::RecordNotFound
    render plain: "Lien invalide ou expiré.", status: :not_found
  end
end
