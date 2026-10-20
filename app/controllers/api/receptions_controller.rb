# Module « Réception de commande et appel de livraison » — ENVIRONNEMENT TEST
# uniquement (admin avec un profil test actif, cf. Api::TestProfilesController).
# La commande d'achat est celle de l'e-shop ; périmètre = Order.visible_to.
# Aucun prix n'est exposé : quantités et statuts seulement.
class Api::ReceptionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :require_test_environment
  before_action :load_order, only: [ :order, :update_order, :create_call, :create_reception ]

  # Liste des commandes suivies (hors annulées / refusées / remplacées).
  def orders
    scope = Order.visible_to(current_user).where(cancelled_at: nil).where.not(approval_status: "refused")
    scope = scope.includes(:supplier, :revisions, order_lines: :product, receptions: [ :lines, :scans ], delivery_calls: :lines)
                 .order(created_at: :desc).limit(300)
    render json: scope.reject(&:superseded?).map { |o| order_row(o) }
  end

  def order
    render json: order_detail(@order)
  end

  # Type de gestion (C1…C5) et marquage « facturé ».
  def update_order
    if params.key?(:reception_type)
      type = params[:reception_type].to_s
      return render json: { error: "Type inconnu." }, status: :unprocessable_entity unless type.blank? || OrderReceptionTracker::TYPES.key?(type)

      @order.reception_type = type.presence
    end
    @order.invoiced_at = (ActiveModel::Type::Boolean.new.cast(params[:invoiced]) ? (@order.invoiced_at || Time.current) : nil) if params.key?(:invoiced)
    @order.save!
    render json: order_detail(@order.reload)
  end

  def create_call
    call = @order.delivery_calls.new(user: current_user, planned_on: parse_date(params[:planned_on]),
                                     planned_time: params[:planned_time].to_s.strip.presence, notes: params[:notes].to_s.strip.presence,
                                     slots: clean_slots(params[:slots]))
    lines = line_params(params[:lines])
    return render json: { error: "Indiquez au moins une quantité à livrer." }, status: :unprocessable_entity if lines.empty? && @order.reception_type != "C5"

    DeliveryCall.transaction do
      call.save!
      lines.each { |l| call.lines.create!(order_line: l[:order_line], quantity: l[:quantity]) }
    end
    render json: order_detail(@order.reload), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def update_call
    call = DeliveryCall.find(params[:id])
    return head(:not_found) unless visible?(call.order)

    call.planned_on = parse_date(params[:planned_on]) if params[:planned_on].present?
    call.planned_time = params[:planned_time].to_s.strip.presence if params.key?(:planned_time)
    call.status = params[:status].to_s if DeliveryCall::STATUSES.include?(params[:status].to_s)
    call.save!
    render json: order_detail(call.order.reload)
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def create_reception
    rec = @order.receptions.new(user: current_user, received_on: parse_date(params[:received_on]) || Date.current,
                                bl_number: params[:bl_number].to_s.strip.presence, comment: params[:comment].to_s.strip.presence,
                                delivery_call_id: @order.delivery_calls.find_by(id: params[:delivery_call_id])&.id,
                                status: Reception::STATUSES.include?(params[:status].to_s) ? params[:status].to_s : "accepte",
                                progress_percent: params[:progress_percent].presence)
    lines = line_params(params[:lines], accepted: true)
    scans = Array(params[:scans]).select { |f| f.respond_to?(:read) }
    if @order.reception_type == "C5"
      return render json: { error: "Indiquez l'avancement validé (%)." }, status: :unprocessable_entity if rec.progress_percent.nil?
    elsif lines.empty?
      return render json: { error: "Indiquez au moins une quantité livrée." }, status: :unprocessable_entity
    end
    return render json: { error: "Maximum #{Reception::MAX_SCANS} scans par réception." }, status: :unprocessable_entity if scans.size > Reception::MAX_SCANS

    Reception.transaction do
      rec.save!
      lines.each { |l| rec.lines.create!(order_line: l[:order_line], quantity_received: l[:quantity], quantity_accepted: l[:accepted]) }
      scans.each { |f| store_scan(rec, f) }
      rec.delivery_call&.update!(status: "delivered") if rec.delivery_call && fully_received_call?(rec.delivery_call)
      # Commande soldée : plus aucun appel ne reste ouvert.
      @order.reload
      @order.delivery_calls.select(&:open?).each { |c| c.update!(status: "delivered") } if OrderReceptionTracker.new(@order).accepted_percent >= 100
    end
    render json: order_detail(@order.reload), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def add_scans
    rec = Reception.find(params[:id])
    return head(:not_found) unless visible?(rec.order)

    files = Array(params[:scans]).select { |f| f.respond_to?(:read) }
    return render json: { error: "Aucun fichier reçu." }, status: :unprocessable_entity if files.empty?
    return render json: { error: "Maximum #{Reception::MAX_SCANS} scans par réception." }, status: :unprocessable_entity if rec.scans.count + files.size > Reception::MAX_SCANS

    Reception.transaction { files.each { |f| store_scan(rec, f) } }
    render json: order_detail(rec.order.reload), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def scan
    rec = Reception.find(params[:id])
    return head(:not_found) unless visible?(rec.order)

    s = rec.scans.find(params[:scan_id])
    send_data s.data, type: s.content_type, filename: s.filename.presence || "bl-#{s.id}", disposition: "inline"
  end

  # Correction d'une saisie erronée : admin seulement.
  def destroy_reception
    rec = Reception.find(params[:id])
    return head(:not_found) unless visible?(rec.order)

    order = rec.order
    rec.destroy!
    render json: order_detail(order.reload)
  end

  private

  def require_test_environment
    return if Api::TestProfilesController.active_profile(session, current_user)

    render json: { error: "Module disponible uniquement dans l'environnement test." }, status: :forbidden
  end

  def visible?(order) = Order.visible_to(current_user).exists?(order.id)

  def load_order
    @order = Order.visible_to(current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Commande introuvable" }, status: :not_found
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def clean_slots(raw)
    Array(raw).filter_map do |s|
      time = (s.respond_to?(:[]) ? s[:time] : nil).to_s.strip
      label = (s.respond_to?(:[]) ? s[:label] : nil).to_s.strip
      { "time" => time, "label" => label } if time.present? || label.present?
    end
  end

  # Lignes [{ id, quantity[, accepted] }] limitées à celles de la commande ; quantités > 0.
  def line_params(raw, accepted: false)
    by_id = @order.order_lines.index_by(&:id)
    # Formulaire multipart : lines[0][id]=… arrive en Hash indexé, pas en Array.
    raw = raw.values if raw.respond_to?(:values)
    Array(raw).filter_map do |l|
      ol = by_id[l[:id].to_i] or next
      qty = BigDecimal(l[:quantity].to_s.tr(",", ".").presence || "0") rescue 0.to_d
      next unless qty.positive?

      acc = accepted ? (BigDecimal(l[:accepted].to_s.tr(",", ".")) rescue qty) : qty
      { order_line: ol, quantity: qty, accepted: [ [ acc, 0.to_d ].max, qty ].min }
    end
  end

  def fully_received_call?(call)
    delivered = Hash.new(0.to_d)
    call.receptions.includes(:lines).each { |r| r.lines.each { |l| delivered[l.order_line_id] += l.quantity_received } }
    call.lines.all? { |l| delivered[l.order_line_id] >= l.quantity }
  end

  def store_scan(rec, file)
    data = file.read
    rec.scans.create!(filename: File.basename(file.original_filename.to_s)[0, 120], content_type: file.content_type.to_s, byte_size: data.bytesize, data: data)
  end

  def order_row(o)
    tr = OrderReceptionTracker.new(o)
    { id: o.id, no: o.number, date: (o.order_date || o.created_at.to_date).strftime("%d.%m.%Y"), supplier: o.supplier&.name,
      chantier: o.chantier_name || "—", user_name: o.user&.full_name,
      approval: o.approval_status.presence || o.status }.merge(tr.summary)
  end

  def order_detail(o)
    o = Order.includes(:supplier, order_lines: :product, receptions: [ :lines, :scans, :user ], delivery_calls: [ :lines, :user ]).find(o.id)
    tr = OrderReceptionTracker.new(o)
    order_row(o).merge(
      invoicedAt: o.invoiced_at&.strftime("%d.%m.%Y"),
      deliveryDate: o.notes.to_s[/Délai souhaité:\s*([^|]+)/, 1]&.strip,
      address: o.delivery_address,
      typeLabels: OrderReceptionTracker::TYPES,
      lines: tr.line_rows,
      calls: o.delivery_calls.sort_by { |c| [ c.planned_on, c.planned_time.to_s ] }.map { |c|
        { id: c.id, plannedOn: c.planned_on.strftime("%d.%m.%Y"), plannedOnIso: c.planned_on.iso8601, time: c.planned_time, status: c.status,
          notes: c.notes, slots: c.slots, user: c.user&.full_name,
          lines: c.lines.map { |l| { id: l.order_line_id, quantity: l.quantity.to_f } } }
      },
      receptionList: o.receptions.sort_by { |r| [ r.received_on, r.id ] }.reverse.map { |r|
        { id: r.id, receivedOn: r.received_on.strftime("%d.%m.%Y"), bl: r.bl_number, status: r.status, comment: r.comment,
          progress: r.progress_percent&.to_f, callId: r.delivery_call_id, user: r.user&.full_name,
          lines: r.lines.map { |l| { id: l.order_line_id, received: l.quantity_received.to_f, accepted: l.quantity_accepted.to_f } },
          scans: r.scans.map { |s| { id: s.id, name: s.filename, type: s.content_type, size: s.byte_size, url: "/api/reception/receptions/#{r.id}/scans/#{s.id}" } } }
      }
    )
  end
end
