class Api::OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    chantier      = params[:chantier].to_s.strip
    delai         = params[:delai].to_s.strip
    supplier_name = params[:supplier].to_s.strip
    items         = params[:items] || []

    return render json: { error: 'Panier vide' }, status: :unprocessable_entity if items.blank?

    supplier = Supplier.find_or_create_by!(name: supplier_name) do |s|
      s.email = "commandes@#{supplier_name.downcase.gsub(/[^a-z0-9]/, '')}.ch"
    end

    order = Order.create!(
      supplier: supplier,
      status: 'sent',
      order_date: Date.today,
      notes: "Chantier: #{chantier} | Délai souhaité: #{delai}"
    )

    items.each do |item|
      product = Product.find_or_create_by!(reference: item[:article].to_s) do |p|
        p.name       = item[:designation].to_s
        p.unit_price = item[:prix].to_f
        p.supplier   = supplier
      end
      order.order_lines.create!(
        product:    product,
        quantity:   item[:qty].to_i,
        unit_price: item[:prix].to_f
      )
    end

    OrderMailer.send_order(order).deliver_now
    render json: { success: true, order_number: order.number }, status: :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
