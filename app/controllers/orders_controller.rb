class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy, :send_to_supplier]

  def index
    @orders = Order.all.includes(:supplier)
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
      redirect_to @order, notice: "Commande mise à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy
    redirect_to orders_url, notice: "Commande supprimée."
  end

  def send_to_supplier
    OrderMailer.send_order(@order).deliver_now
    @order.update(status: 'sent')
    redirect_to @order, notice: "Commande envoyée au fournisseur."
  rescue => e
    redirect_to @order, alert: "Erreur lors de l'envoi: #{e.message}"
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:supplier_id, :status, :notes, :order_date)
  end
end
