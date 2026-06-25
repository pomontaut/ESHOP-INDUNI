class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy, :send_to_supplier, :download_pdf]

  def index
    @orders = Order.includes(:supplier).all.order(created_at: :desc)
  end

  def show
    @order_lines = @order.order_lines.includes(:product)
  end

  def new
    @order = Order.new(status: 'draft', order_date: Date.today)
    @suppliers = Supplier.all.order(:name)
  end

  def edit
    @suppliers = Supplier.all.order(:name)
  end

  def create
    @order = Order.new(order_params)
    if @order.save
      redirect_to @order, notice: 'Commande créée avec succès.'
    else
      @suppliers = Supplier.all.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @order.update(order_params)
      redirect_to @order, notice: 'Commande mise à jour avec succès.'
    else
      @suppliers = Supplier.all.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy
    redirect_to orders_url, notice: 'Commande supprimée.'
  end

  def send_to_supplier
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string('orders/show', formats: [:pdf], layout: 'pdf')
    )
    OrderMailer.send_order(@order, pdf).deliver_now
    @order.update(status: 'sent')
    redirect_to @order, notice: "Commande envoyée à #{@order.supplier.name}."
  end

  def download_pdf
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string('orders/show', formats: [:pdf], layout: 'pdf')
    )
    send_data pdf, filename: "commande_#{@order.number}.pdf", type: 'application/pdf'
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:supplier_id, :status, :notes, :order_date)
  end
end
