require "csv"

# Admin > Commandes : export de sauvegarde puis remise à zéro des commandes
# passées (ex. après une phase de tests, avant la mise en service réelle).
# Irréversible : réservé aux administrateurs permanents, confirmation tapée,
# export CSV proposé avant. Ne touche ni aux fournisseurs, ni aux articles, ni
# aux utilisateurs, ni aux chantiers.
class Admin::OrdersController < ApplicationController
  before_action :require_permanent_admin
  CONFIRMATION_PHRASE = "VIDER LES COMMANDES".freeze

  def index
    @count        = Order.count
    @line_count   = OrderLine.count
    @by_supplier  = Order.joins(:supplier).group("suppliers.name").order("suppliers.name").count
    @last_number  = Order.where("number LIKE 'ESHOP_INDUNI_%'").pluck(:number)
                         .filter_map { |n| n[/\AESHOP_INDUNI_(\d+)/, 1]&.to_i }.max
    @phrase       = CONFIRMATION_PHRASE
  end

  def export
    csv = CSV.generate(col_sep: ";") do |out|
      out << [ "N°", "Date", "Fournisseur", "Chantier", "Auteur", "Statut", "Marchandise HT", "Frais annexes", "Total HT", "Envoyée à", "Créée le" ]
      Order.includes(:supplier, :user, :order_lines).order(:id).each do |o|
        out << [ o.number, o.order_date, o.supplier&.name, o.chantier_name, o.user&.full_name,
                 o.approval_status.presence || o.status, o.total.to_f.round(2), o.extra_charges_total.round(2),
                 o.grand_total.to_f.round(2), o.sent_to, o.created_at&.strftime("%d.%m.%Y %H:%M") ]
      end
    end
    send_data "﻿#{csv}", filename: "commandes_#{Date.current.strftime('%Y%m%d')}.csv", type: "text/csv; charset=utf-8"
  end

  def purge
    unless params[:confirmation].to_s.strip == CONFIRMATION_PHRASE
      return redirect_to admin_orders_path, alert: "Confirmation incorrecte : tapez exactement « #{CONFIRMATION_PHRASE} »."
    end

    # Commandes à conserver (ex. une vraie commande) : numéros exacts, sinon rien n'est supprimé.
    keep = params[:keep].to_s.upcase.split(/[\s,;]+/).reject(&:blank?).uniq
    unknown = keep - Order.where(number: keep).pluck(:number)
    if unknown.any?
      return redirect_to admin_orders_path, alert: "Commande(s) à conserver introuvable(s) : #{unknown.join(', ')}. Rien n'a été supprimé."
    end

    doomed = Order.where.not(number: keep)
    count = doomed.count
    reset = params[:reset_numbering] == "1" && keep.empty?
    Order.transaction do
      last = Order.where("number LIKE 'ESHOP_INDUNI_%'").pluck(:number).filter_map { |n| n[/\AESHOP_INDUNI_(\d+)/, 1]&.to_i }.max.to_i
      reset ? OrderNumberFloor.reset! : OrderNumberFloor.raise_to!(last)
      OrderLine.where(order_id: doomed.select(:id)).delete_all
      # Module Réception (sans clé étrangère SQL) : appels, réceptions, scans.
      rec_ids = Reception.where(order_id: doomed.select(:id)).select(:id)
      ReceptionScan.where(reception_id: rec_ids).delete_all
      ReceptionLine.where(reception_id: rec_ids).delete_all
      Reception.where(order_id: doomed.select(:id)).delete_all
      DeliveryCallLine.where(delivery_call_id: DeliveryCall.where(order_id: doomed.select(:id)).select(:id)).delete_all
      DeliveryCall.where(order_id: doomed.select(:id)).delete_all
      doomed.delete_all
    end
    kept = keep.any? ? " Conservée(s) : #{keep.join(', ')}." : ""
    redirect_to admin_orders_path, notice: "#{count} commande(s) supprimée(s).#{kept} Numérotation : #{reset ? 'repart à ESHOP_INDUNI_01' : 'continue après le dernier numéro attribué'}."
  end

  private

  def require_permanent_admin
    return if current_user&.admin? && User::PERMANENT_ADMIN_EMAILS.include?(current_user.email.to_s.downcase)

    redirect_to root_path, alert: "Accès réservé au propriétaire de l'application."
  end
end
