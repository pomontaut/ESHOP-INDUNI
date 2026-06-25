class OrderLinesController < ApplicationController
  before_action :set_order

  def create
    @order_line = @order.order_lines.build(order_line_params)
    if @order_line.save
      redirect_to @order, notice: "Ligne ajoutée."
    else
      redirect_to @order, alert: "Erreur lors de l'ajout de la ligne."
    end
  end

  def destroy
    @order_line = @order.order_lines.find(params[:id])
    @order_line.destroy
    redirect_to @order, notice: "Ligne supprimée."
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def order_line_params
    params.require(:order_line).permit(:product_id, :quantity, :unit_price)
  end
end
