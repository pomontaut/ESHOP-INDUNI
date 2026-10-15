# Relance fournisseur : une commande envoyée par e-mail dont le fournisseur n'a
# pas accusé réception (lien de confirmation ou « Marquer reçu ») après 24 h est
# relancée UNE fois automatiquement, les jours ouvrés entre 7 h et 18 h (heure de
# Zurich). Le dashboard permet aussi de relancer à la main.
#
# L'envoi automatique est désactivé tant que RELANCE_AUTO_ENABLED=true n'est pas
# défini (le texte ci-dessous doit d'abord être validé).
class OrderRelance
  TIME_ZONE  = "Europe/Zurich".freeze
  WAIT_HOURS = 24
  WORK_DAYS  = (1..5)      # lundi à vendredi
  WORK_HOURS = (7...18)    # de 7h00 à 17h59

  SUBJECT = "Relance — Commande N° %<number>s".freeze

  BODY = <<~TEXT.freeze
    Bonjour,

    Sauf erreur de notre part, nous n'avons pas encore reçu de confirmation pour notre commande N° %<number>s du %<date>s (chantier : %<chantier>s), qui vous a été transmise par e-mail il y a plus de 24 heures.

    Pourriez-vous, s'il vous plaît, nous confirmer la bonne réception de cette commande ainsi que la date de livraison prévue, en cliquant sur le bouton ci-dessous ou en répondant directement à ce message ?

    Si cette confirmation nous a déjà été transmise, merci de ne pas tenir compte de ce rappel.

    Restant à votre disposition pour toute information complémentaire.

    Cordialement
    INDUNI & Cie SA
    Avenue des Grandes-Communes 6
    1213 Petit-Lancy
  TEXT

  def self.enabled?
    ENV["RELANCE_AUTO_ENABLED"] == "true"
  end

  def self.working_time?(time = Time.current)
    local = time.in_time_zone(TIME_ZONE)
    WORK_DAYS.cover?(local.wday) && WORK_HOURS.cover?(local.hour)
  end

  def self.subject(order)
    format(SUBJECT, number: order.number)
  end

  def self.body(order)
    chantier = order.notes.to_s.match(/Chantier:\s*([^|]+)/)&.captures&.first&.strip.presence || "—"
    date = (order.email_sent_at || order.created_at).in_time_zone(TIME_ZONE).strftime("%d.%m.%Y")
    format(BODY, number: order.number, date: date, chantier: chantier)
  end

  # Commandes envoyées depuis plus de 24 h, sans retour du fournisseur, jamais
  # relancées, ni annulées ni remplacées.
  def self.due(now = Time.current)
    Order.where.not(email_sent_at: nil)
         .where(email_sent_at: ..(now - WAIT_HOURS.hours), reception_confirmed_at: nil, cancelled_at: nil, relance_sent_at: nil)
         .where(approval_status: [ nil, "approved" ])
         .includes(:supplier, :user, :revisions)
         .reject(&:superseded?)
  end

  # Relance manuelle possible tant que le fournisseur n'a pas répondu.
  def self.relanceable?(order)
    order.email_sent_at.present? && !order.reception_confirmed? && !order.cancelled? && !order.superseded?
  end

  # Appelé périodiquement : envoie les relances dues si on est dans la fenêtre
  # ouvrée. Réserve l'envoi en base avant d'écrire (pas de double relance même
  # si deux processus tournent) et le libère si l'e-mail échoue.
  def self.run_due!(now = Time.current)
    return 0 unless enabled? && working_time?(now)

    due(now).count do |order|
      claimed = Order.where(id: order.id, relance_sent_at: nil).update_all(relance_sent_at: now, relance_kind: "auto")
      next false if claimed.zero?

      begin
        OrderMailer.relance(order).deliver_now
        true
      rescue => e
        Order.where(id: order.id).update_all(relance_sent_at: nil, relance_kind: nil)
        Rails.logger.error("[relance] échec commande #{order.number} : #{e.message}")
        false
      end
    end
  end

  def self.deliver!(order, now = Time.current, kind: "manuel")
    OrderMailer.relance(order).deliver_now
    order.update!(relance_sent_at: now, relance_kind: kind)
  end
end
