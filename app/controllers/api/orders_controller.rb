class Api::OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    orders = current_user&.admin? ? Order.all : Order.where(user: current_user)
    orders = orders.includes(:supplier, :order_lines, :user).order(created_at: :desc).limit(100)
    render json: orders.map { |o|
      chantier = o.notes.to_s.match(/Chantier:\s*([^|]+)/)&.captures&.first&.strip || "—"
      {
        id:              o.id,
        no:              o.number,
        date:            o.order_date&.strftime('%d.%m.%Y') || o.created_at.strftime('%d.%m.%Y'),
        supplier:        o.supplier&.name,
        chantier:        chantier,
        total:           o.total.to_f.round(2),
        status:          o.approval_status.presence || o.status,
        user_name:       o.user&.full_name,
        user_sector:     o.user&.sector,
        items:           o.order_lines.map { |l|
          { article: l.product&.reference, designation: l.product&.name, qty: l.quantity, prix: l.unit_price.to_f }
        }
      }
    }
  end

  def create
    chantier      = params[:chantier].to_s.strip
    delai         = params[:delai].to_s.strip
    supplier_name = params[:supplier].to_s.strip
    items         = params[:items] || []

    return render json: { error: 'Panier vide' }, status: :unprocessable_entity if items.blank?

    supplier = Supplier.find_or_create_by!(name: supplier_name) do |s|
      s.email = "commandes@#{supplier_name.downcase.gsub(/[^a-z0-9]/, '')}.ch"
    end

    # Calculate total to check against user's order limit
    total = items.sum { |item| item[:prix].to_f * item[:qty].to_i }
    limit = current_user&.order_limit
    needs_approval = limit.present? && total > limit.to_f

    approval_status = needs_approval ? 'pending_approval' : 'approved'
    order_status    = needs_approval ? 'pending_approval' : 'sent'

    order = Order.create!(
      supplier:        supplier,
      user:            current_user,
      status:          order_status,
      approval_status: approval_status,
      approver_email:  current_user&.approver_email,
      order_date:      Date.today,
      notes:           "Chantier: #{chantier} | Délai souhaité: #{delai}"
    )

    items.each do |item|
      product = Product.find_or_create_by!(supplier: supplier, reference: item[:article].to_s) do |p|
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

    if needs_approval
      # Send approval request to N+1 instead of order to supplier
      OrderMailer.approval_request(order).deliver_now rescue nil
      render json: {
        success:          true,
        needs_approval:   true,
        order_id:         order.id,
        order_number:     order.number,
        message:          "Commande #{order.number} enregistrée. Votre commande dépasse votre plafond de #{number_with_commas(limit)} CHF — une demande d'approbation a été envoyée à #{current_user.approver_email}."
      }, status: :ok
    else
      # Send the order directly to the supplier, with the bon de commande PDF attached
      pdf_content = render_order_pdf(order)
      OrderMailer.send_order(order, pdf_content).deliver_now
      render json: {
        success:        true,
        needs_approval: false,
        order_id:       order.id,
        order_number:   order.number,
        supplier_email: supplier.email,
        supplier_name:  supplier.name
      }, status: :ok
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def number_with_commas(n)
    n.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1'").reverse
  end
end
