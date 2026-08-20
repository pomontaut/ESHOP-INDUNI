class Api::OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Lets the client show/pre-fill the real order number in the "Vérifier et
  # envoyer" step before the order actually exists. See Order.next_number.
  def next_number
    render json: { number: Order.next_number }
  end

  # Manual fallback for the reception accusé — the automated e-mail button
  # depends on the fournisseur actually receiving and trusting an e-mail sent
  # from a generic, unverified sender address (see indunieshop.ch domain
  # verification), which isn't reliable enough on its own. This lets whoever
  # created the order mark it received themselves (phone call, an ordinary
  # e-mail reply, etc.) — no dependency on the fournisseur clicking anything.
  def confirm_reception
    order = current_user&.admin? ? Order.find(params[:id]) : Order.find_by!(id: params[:id], user: current_user)
    order.update!(reception_confirmed_at: Time.current) unless order.reception_confirmed?
    render json: { success: true, receptionConfirmedAt: order.reception_confirmed_at.strftime("%d.%m.%Y %H:%M") }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Commande introuvable" }, status: :not_found
  end

  def index
    orders = current_user&.admin? ? Order.all : Order.where(user: current_user)
    orders = orders.includes(:supplier, :order_lines, :user).order(created_at: :desc).limit(100)
    render json: orders.map { |o|
      chantier = o.notes.to_s.match(/Chantier:\s*([^|]+)/)&.captures&.first&.strip || "—"
      {
        id:              o.id,
        no:              o.number,
        date:            o.order_date&.strftime("%d.%m.%Y") || o.created_at.strftime("%d.%m.%Y"),
        supplier:        o.supplier&.name,
        chantier:        chantier,
        total:           o.total.to_f.round(2),
        status:          o.approval_status.presence || o.status,
        user_name:       o.user&.full_name,
        user_sector:     o.user&.sector,
        receptionConfirmedAt: o.reception_confirmed_at&.strftime("%d.%m.%Y %H:%M"),
        items:           o.order_lines.map { |l|
          { article: l.product&.reference, designation: l.product&.name, qty: l.quantity, prix: l.unit_price.to_f, catalogPrix: l.catalog_price&.to_f }
        }
      }
    }
  end

  # Converts a client-built bon de commande HTML preview into a real PDF, so
  # the "Ouvrir dans Outlook" fallback (a plain mailto: link can never carry
  # an attachment itself — that's a hard browser/OS restriction) can hand the
  # user an actual PDF to attach instead of an HTML file requiring a manual
  # print-to-PDF step. Deliberately independent from the Order/OrderLine
  # models — it only ever converts an already-rendered HTML string, the same
  # way render_order_pdf does for the real send flow, so it can't be broken
  # by unrelated Order changes.
  def preview_pdf
    html = params[:html].to_s
    return render json: { error: "Contenu HTML manquant." }, status: :unprocessable_entity if html.blank?

    pdf = WickedPdf.new.pdf_from_string(html, disable_local_file_access: true, no_stop_slow_scripts: true)
    send_data pdf, filename: "#{params[:filename].presence || 'bon_de_commande'}.pdf", type: "application/pdf", disposition: "attachment"
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def create
    chantier      = params[:chantier].to_s.strip
    delai         = params[:delai].to_s.strip
    supplier_name = params[:supplier].to_s.strip
    items         = params[:items] || []

    return render json: { error: "Panier vide" }, status: :unprocessable_entity if items.blank?

    supplier = Supplier.find_or_create_by!(name: supplier_name) do |s|
      s.email = "commandes@#{supplier_name.downcase.gsub(/[^a-z0-9]/, '')}.ch"
    end

    # Calculate total to check against user's order limit
    total = items.sum { |item| item[:prix].to_f * item[:qty].to_i }
    limit = current_user&.order_limit
    needs_approval = limit.present? && total > limit.to_f

    approval_status = needs_approval ? "pending_approval" : "approved"
    order_status    = needs_approval ? "pending_approval" : "sent"

    modifies_order = Order.find_by(id: params[:modifies_order_id]) if params[:modifies_order_id].present?

    order = Order.create!(
      supplier:        supplier,
      user:            current_user,
      status:          order_status,
      approval_status: approval_status,
      approver_email:  current_user&.approver_email,
      order_date:      Date.today,
      notes:           "Chantier: #{chantier} | Délai souhaité: #{delai}",
      modifies_order:  modifies_order
    )

    items.each do |item|
      product = Product.find_or_create_by!(supplier: supplier, reference: item[:article].to_s) do |p|
        p.name       = item[:designation].to_s
        p.unit_price = item[:prix].to_f
        p.supplier   = supplier
      end
      order.order_lines.create!(
        product:      product,
        quantity:     item[:qty].to_i,
        unit_price:   item[:prix].to_f,
        catalog_price: item[:catalogPrix].presence && item[:catalogPrix].to_f
      )
    end

    if modifies_order
      # Best-effort: a notification failure must never break the order itself.
      diff = build_order_diff(modifies_order, items)
      OrderMailer.order_modified(order, modifies_order, diff, current_user).deliver_now rescue nil
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
      # Send the order directly to the supplier, with the bon de commande PDF
      # attached. `to`/`cc`/`subject`/`body` let the user override the
      # recipients and message from the "Vérifier et envoyer" confirmation
      # step instead of always using the generic defaults.
      to = sanitize_email_list(params[:to])
      cc = sanitize_email_list(params[:cc])
      # The order's author is always copied — even if they clear the field —
      # so a copy always lands in their own mailbox as proof the order was
      # actually sent (combined with the read receipt below, proof it was
      # read too).
      cc_addresses = (cc || "").split(",").map(&:strip)
      cc_addresses << current_user.email if current_user&.email.present?
      cc = cc_addresses.uniq.join(", ").presence
      subject = params[:subject].to_s.strip.presence
      body    = params[:body].to_s.strip.presence
      pdf_content = render_order_pdf(order)
      OrderMailer.send_order(order, pdf_content, to: to, cc: cc, subject: subject, body: body, read_receipt_to: current_user&.email).deliver_now
      render json: {
        success:        true,
        needs_approval: false,
        order_id:       order.id,
        order_number:   order.number,
        supplier_email: to.presence || supplier.email,
        supplier_name:  supplier.name
      }, status: :ok
    end
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  # Compares the new order's items against the order it modifies, so the
  # admin notification can show exactly what changed rather than just the
  # fact that *something* changed.
  def build_order_diff(original_order, items)
    original = original_order.order_lines.includes(:product).index_by { |l| l.product.reference }
    new_items = items.index_by { |it| it[:article].to_s }

    added = new_items.except(*original.keys).map { |ref, it|
      { reference: ref, designation: it[:designation].to_s, qty: it[:qty].to_i, prix: it[:prix].to_f }
    }
    removed = original.except(*new_items.keys).map { |ref, line|
      { reference: ref, designation: line.product.name, qty: line.quantity, prix: line.unit_price.to_f }
    }
    changed = (original.keys & new_items.keys).filter_map { |ref|
      line = original[ref]
      it   = new_items[ref]
      next if line.quantity == it[:qty].to_i && line.unit_price.to_f.round(2) == it[:prix].to_f.round(2)
      { reference: ref, designation: it[:designation].to_s,
        old_qty: line.quantity, new_qty: it[:qty].to_i,
        old_prix: line.unit_price.to_f, new_prix: it[:prix].to_f }
    }
    { added: added, removed: removed, changed: changed }
  end

  EMAIL_RE = /\A[^@\s,]+@[^@\s,]+\.[^@\s,]+\z/

  # Comma-separated list of addresses, typed freely by the user before
  # sending: keep only the entries that look like real e-mail addresses
  # (also guards against header-injection via newlines) and drop the rest
  # silently rather than failing the whole send.
  def sanitize_email_list(raw)
    return nil if raw.blank?
    raw.to_s.split(",").map(&:strip).select { |a| a.match?(EMAIL_RE) }.presence&.join(", ")
  end

  def number_with_commas(n)
    n.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1'").reverse
  end
end
