class ApprovalsController < ApplicationController
  skip_before_action :require_login

  before_action :load_order

  def show
  end

  def approve
    if @order.pending_approval?
      @order.update!(approval_status: 'approved', status: 'approved')
      OrderMailer.approval_approved(@order).deliver_now rescue nil
    end
    render plain: "✅ Commande #{@order.number} approuvée. Le rédacteur a été notifié.", content_type: "text/plain"
  end

  def refuse
    comment = params[:comment].to_s.strip
    if @order.pending_approval?
      @order.update!(approval_status: 'refused', status: 'refused', approval_comment: comment)
      OrderMailer.approval_refused(@order).deliver_now rescue nil
    end
    render plain: "❌ Commande #{@order.number} refusée. Le rédacteur a été notifié.", content_type: "text/plain"
  end

  private

  def load_order
    @order = Order.find_by!(approval_token: params[:token])
  rescue ActiveRecord::RecordNotFound
    render plain: "Lien invalide ou expiré.", status: :not_found
  end
end
