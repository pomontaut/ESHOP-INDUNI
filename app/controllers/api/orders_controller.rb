class Api::OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Toute commande dépassant ce montant nécessite la validation du conducteur
  # de travaux du chantier concerné, quels que soient le plafond personnel de
  # l'utilisateur ou le seuil propre au fournisseur.
  GLOBAL_APPROVAL_THRESHOLD = 5000

  # Profils dont le N+1 par défaut est le conducteur de travaux du chantier
  # de la commande, plutôt que leur approbateur personnel habituel (voir
  # User::JOB_FUNCTIONS).
  SITE_LEAD_JOB_FUNCTIONS = [ "CONTREMAITRE", "CHEF D'EQUIPE" ].freeze

  # Lets the client show/pre-fill the real order number in the "Vérifier et
  # envoyer" step before the order actually exists. See Order.next_number.
  def next_number
    render json: { number: Order.next_number }
  end

  # Manual fallback for the reception accusé — the automated e-mail button
  # depends on the fournisseur actually receiving, opening and clicking a
  # link in the e-mail, which isn't reliable enough on its own (spam
  # filters, someone else opening the mailbox, etc.). This lets whoever
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
    # Prix net confidentiel (fournisseur sous accord de confidentialité, ex.
    # Sika) : seule l'Analyse achat (accès restreint aux Achats) doit voir le
    # vrai montant. On le masque ici pour quiconque n'a pas ce droit, pour
    # que ni le Dashboard (accessible aux exploitants) ni l'onglet réseau du
    # navigateur ne puissent jamais l'exposer — `confidential` reste vrai
    # même pour un utilisateur autorisé, pour que le Dashboard (qui, lui,
    # doit toujours le masquer, indépendamment des droits du visiteur) sache
    # l'afficher comme tel.
    can_see_confidential = current_user&.admin? || current_user&.effective_can_view_analysis?
    render json: orders.map { |o|
      chantier = o.notes.to_s.match(/Chantier:\s*([^|]+)/)&.captures&.first&.strip || "—"
      confidential = o.supplier&.confidential_pricing?
      masked = confidential && !can_see_confidential
      {
        id:              o.id,
        no:              o.number,
        date:            o.order_date&.strftime("%d.%m.%Y") || o.created_at.strftime("%d.%m.%Y"),
        supplier:        o.supplier&.name,
        chantier:        chantier,
        total:           masked ? 0 : o.total.to_f.round(2),
        confidential:    confidential,
        status:          o.approval_status.presence || o.status,
        user_name:       o.user&.full_name,
        user_sector:     o.user&.sector,
        receptionConfirmedAt: o.reception_confirmed_at&.strftime("%d.%m.%Y %H:%M"),
        emailSent:       o.email_sent_at.present?,
        items:           o.order_lines.map { |l|
          { article: l.product&.reference, designation: l.product&.name, qty: l.quantity,
            prix: masked ? 0 : l.unit_price.to_f, catalogPrix: masked ? nil : l.catalog_price&.to_f }
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
    chantier           = params[:chantier].to_s.strip
    delai              = params[:delai].to_s.strip
    supplier_name      = params[:supplier].to_s.strip
    items              = params[:items] || []
    contact            = params[:contact].to_s.strip.presence
    phone              = params[:phone].to_s.strip.presence
    delivery_address   = params[:adresse].to_s.strip.presence
    conducteur_travaux = params[:conducteur].to_s.strip.presence

    return render json: { error: "Panier vide" }, status: :unprocessable_entity if items.blank?

    supplier = Supplier.find_or_create_by!(name: supplier_name) do |s|
      s.email = "commandes@#{supplier_name.downcase.gsub(/[^a-z0-9]/, '')}.ch"
    end

    # Prix net confidentiel (ex. Sika) : le client ne l'a jamais vu (masqué
    # dès Api::ProductsController#index), donc item[:prix] vaut 0 — on
    # reconstitue le vrai prix depuis le catalogue pour le plafond
    # d'approbation et pour les lignes de commande elles-mêmes, plutôt que de
    # faire confiance à ce que le client a soumis.
    confidential_prices = if supplier.confidential_pricing?
      Product.where(supplier: supplier, reference: items.map { |item| item[:article].to_s })
             .pluck(:reference, :unit_price).to_h
    end
    resolved_price = ->(item) {
      confidential_prices ? confidential_prices[item[:article].to_s].to_f : item[:prix].to_f
    }

    # Trois règles d'approbation indépendantes, chacune avec son propre
    # approbateur — la plus spécifique l'emporte quand plusieurs sont
    # dépassées à la fois :
    #  1. Seuil propre au fournisseur (contrat catalogue, /admin/fournisseurs)
    #     -> l'acheteur responsable de ce catalogue (Supplier#responsable_achat).
    #  2. Seuil général de CHF 5'000 -> le conducteur de travaux du chantier.
    #  3. Plafond personnel de l'utilisateur -> son approbateur N+1 habituel,
    #     sauf pour un profil Contremaître/Chef d'équipe, dont le N+1 est
    #     toujours le conducteur de travaux du chantier de la commande.
    total = items.sum { |item| resolved_price.call(item) * item[:qty].to_i }
    limit = current_user&.order_limit
    chantier_record = Chantier.find_by(nom: chantier)
    chantier_conducteur_email = chantier_record&.email_conducteur_travaux.presence

    supplier_threshold_exceeded = supplier.approval_threshold.present? && total > supplier.approval_threshold.to_f
    global_threshold_exceeded   = total > GLOBAL_APPROVAL_THRESHOLD
    personal_limit_exceeded     = limit.present? && total > limit.to_f
    needs_approval = supplier_threshold_exceeded || global_threshold_exceeded || personal_limit_exceeded

    fallback_admin_email = -> { User.where(admin: true).order(:id).pick(:email) }
    approver_email =
      if supplier_threshold_exceeded
        resolved_buyer_email(supplier.responsable_achat) || fallback_admin_email.call
      elsif global_threshold_exceeded
        chantier_conducteur_email || fallback_admin_email.call
      elsif personal_limit_exceeded
        if SITE_LEAD_JOB_FUNCTIONS.include?(current_user&.job_function)
          chantier_conducteur_email || current_user&.approver_email.presence || fallback_admin_email.call
        else
          current_user&.approver_email.presence || fallback_admin_email.call
        end
      end

    approval_status = needs_approval ? "pending_approval" : "approved"
    order_status    = needs_approval ? "pending_approval" : "sent"

    modifies_order = Order.find_by(id: params[:modifies_order_id]) if params[:modifies_order_id].present?

    order = Order.create!(
      supplier:           supplier,
      user:               current_user,
      status:             order_status,
      approval_status:    approval_status,
      approver_email:     approver_email,
      order_date:         Date.today,
      notes:              "Chantier: #{chantier} | Délai souhaité: #{delai}",
      modifies_order:     modifies_order,
      contact:            contact,
      phone:              phone,
      delivery_address:   delivery_address,
      conducteur_travaux: conducteur_travaux
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
        unit_price:   resolved_price.call(item),
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
        message:          "Commande #{order.number} enregistrée. #{approval_reason_message(limit, supplier, total)} — une demande d'approbation a été envoyée à #{approver_email}."
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
      # The "Vérifier et envoyer" step pre-fills the subject with a number
      # previewed via next_number *before* the order actually exists (so the
      # user can see/edit the real-looking subject up front) — if another
      # order is created in the meantime, that preview goes stale and would
      # otherwise ship with the wrong number in the subject while the PDF
      # attachment (built from the real, just-created order) is correct.
      # The order number itself is never user-editable content, so any
      # ESHOP_NN pattern found is corrected to the real one rather than left
      # to silently mismatch the attachment.
      subject = subject.gsub(/ESHOP_\d+/, order.number) if subject&.match?(/ESHOP_\d+/)
      body    = params[:body].to_s.strip.presence
      # Persisted so a failed send can be retried later (see #resend) with the
      # exact same recipients/message, instead of falling back to generic
      # defaults — and so the order is never silently mistaken for "sent"
      # (see email_sent_at below) if the mailer call raises.
      order.update!(sent_to: to, sent_cc: cc, sent_subject: subject, sent_body: body)
      pdf_content = render_order_pdf(order)
      OrderMailer.send_order(order, pdf_content, to: to, cc: cc, subject: subject, body: body, read_receipt_to: current_user&.email).deliver_now
      order.update!(email_sent_at: Time.current)
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
    # The order (and its lines) is already committed at this point even if
    # the e-mail itself failed to send — email_sent_at staying blank is what
    # lets the dashboard offer a "Renvoyer" action instead of the order
    # silently looking identical to one that was actually sent.
    render json: { error: e.message, order_number: order&.number }, status: :unprocessable_entity
  end

  # Retries sending a previously-created order whose initial e-mail failed —
  # reuses the exact recipients/subject/body from the original attempt.
  def resend
    order = current_user&.admin? ? Order.find(params[:id]) : Order.find_by!(id: params[:id], user: current_user)
    pdf_content = render_order_pdf(order)
    OrderMailer.send_order(
      order, pdf_content,
      to: order.sent_to, cc: order.sent_cc, subject: order.sent_subject, body: order.sent_body,
      read_receipt_to: order.user&.email
    ).deliver_now
    order.update!(email_sent_at: Time.current)
    render json: { success: true, order_number: order.number }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Commande introuvable" }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Commandes actuellement en attente de LA validation de l'utilisateur
  # connecté (il est l'approbateur résolu — voir #create) — alimente l'onglet
  # dédié "Validation de commande" du SPA, plutôt que de compter uniquement
  # sur les liens Approuver/Refuser envoyés par e-mail.
  def pending_approvals
    return render json: [] unless current_user&.email
    orders = Order.where(approver_email: current_user.email, approval_status: "pending_approval")
                  .includes(:supplier, :user).order(created_at: :desc)
    can_see_confidential = current_user.admin? || current_user.effective_can_view_analysis?
    render json: orders.map { |o|
      chantier = o.notes.to_s.match(/Chantier:\s*([^|]+)/)&.captures&.first&.strip || "—"
      confidential = o.supplier&.confidential_pricing?
      masked = confidential && !can_see_confidential
      {
        id:             o.id,
        no:             o.number,
        date:           o.order_date&.strftime("%d.%m.%Y") || o.created_at.strftime("%d.%m.%Y"),
        supplier:       o.supplier&.name,
        chantier:       chantier,
        total:          masked ? 0 : o.total.to_f.round(2),
        confidential:   confidential,
        requester:      o.user&.full_name,
        requesterEmail: o.user&.email
      }
    }
  end

  def approve
    order = Order.find(params[:id])
    return render json: { error: "Vous n'êtes pas l'approbateur de cette commande." }, status: :forbidden unless authorized_approver?(order)
    if order.pending_approval?
      order.update!(approval_status: "approved", status: "approved")
      OrderMailer.approval_approved(order).deliver_now rescue nil
    end
    render json: { success: true }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Commande introuvable" }, status: :not_found
  end

  def refuse
    order = Order.find(params[:id])
    return render json: { error: "Vous n'êtes pas l'approbateur de cette commande." }, status: :forbidden unless authorized_approver?(order)
    if order.pending_approval?
      order.update!(approval_status: "refused", status: "refused", approval_comment: params[:comment].to_s.strip)
      OrderMailer.approval_refused(order).deliver_now rescue nil
    end
    render json: { success: true }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Commande introuvable" }, status: :not_found
  end

  private

  def authorized_approver?(order)
    current_user&.admin? || (current_user&.email.present? && order.approver_email == current_user.email)
  end

  # Explains which threshold(s) triggered the approval step, so the
  # confirmation message stays accurate regardless of which one(s) fired.
  def approval_reason_message(limit, supplier, total)
    reasons = []
    if supplier.approval_threshold.present? && total > supplier.approval_threshold.to_f
      reasons << "dépasse le seuil de validation Achats de #{number_with_commas(supplier.approval_threshold)} CHF pour #{supplier.name}"
    end
    reasons << "dépasse le seuil général de #{number_with_commas(GLOBAL_APPROVAL_THRESHOLD)} CHF" if total > GLOBAL_APPROVAL_THRESHOLD
    reasons << "dépasse votre plafond de #{number_with_commas(limit)} CHF" if limit.present? && total > limit.to_f
    "Votre commande " + reasons.join(" et ")
  end

  # Retrouve l'e-mail de l'acheteur responsable d'un catalogue (nom choisi
  # sur la fiche fournisseur, voir Supplier::BUYERS) en le faisant
  # correspondre à un compte utilisateur de même prénom/nom. Si cette
  # personne n'a pas encore de compte, l'appelant se replie sur un admin.
  def resolved_buyer_email(buyer_name)
    return nil if buyer_name.blank?
    first_name, last_name = buyer_name.split(" ", 2)
    User.find_by(first_name: first_name, last_name: last_name)&.email
  end

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
