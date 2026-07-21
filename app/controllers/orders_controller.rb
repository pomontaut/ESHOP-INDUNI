class OrdersController < ApplicationController
  before_action :set_order, only: [ :show, :edit, :update, :destroy, :send_to_supplier, :download_eml, :resubmit_approval ]

  def index
    @orders = Order.all.includes(:supplier, :user)
  end

  def show
    @order_line = OrderLine.new
    @products = Product.all
  end

  def new
    @order = Order.new
  end

  def edit
  end

  def create
    @order = Order.new(order_params)
    if @order.save
      redirect_to @order, notice: "Commande créée avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @order.update(order_params)
      # If editing a refused order, reset approval status to pending for resubmission
      if @order.refused?
        @order.update(approval_status: "pending_approval", status: "pending_approval", approval_comment: nil)
      end
      redirect_to @order, notice: "Commande mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy
    redirect_to orders_url, notice: "Commande supprimée."
  end

  def send_to_supplier
    unless @order.approved? || @order.approval_status == "approved" || @order.approval_status.nil?
      return redirect_to @order, alert: "Cette commande doit être approuvée avant d'être envoyée."
    end
    OrderMailer.send_order(@order, render_order_pdf(@order)).deliver_now
    @order.update(status: "sent")
    redirect_to @order, notice: "Commande envoyée au fournisseur."
  rescue => e
    redirect_to @order, alert: "Erreur lors de l'envoi: #{e.message}"
  end

  def download_eml
    mail = OrderMailer.send_order(@order)
    send_data mail.to_s,
              filename: "commande_#{@order.number}.eml",
              type: "message/rfc822",
              disposition: "inline"
  end

  def resubmit_approval
    unless @order.refused?
      return redirect_to @order, alert: "Seules les commandes refusées peuvent être renvoyées."
    end
    @order.update!(
      approval_status: "pending_approval",
      status:          "pending_approval",
      approval_comment: nil
    )
    OrderMailer.approval_request(@order).deliver_now rescue nil
    redirect_to @order, notice: "Demande d'approbation renvoyée à #{@order.approver_email}."
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:supplier_id, :status, :notes, :order_date)
  end
end
