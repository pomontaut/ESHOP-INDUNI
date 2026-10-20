class Order < ApplicationRecord
  # Frais annexes (transport, RPLP, grue, remise de volume...) calculés côté
  # client (voir transportDetailsInduni dans catalogue.html) au moment de
  # l'envoi, et persistés tels quels — [{ "label" => ..., "amount" => ... }, ...]
  # — pour que le bon de commande PDF les reprenne sans avoir à redupliquer
  # cette logique tarifaire par fournisseur côté serveur.
  serialize :extra_charges, coder: JSON, type: Array

  belongs_to :supplier
  belongs_to :user, optional: true
  belongs_to :modifies_order, class_name: "Order", optional: true
  # Commande(s) qui remplacent celle-ci (ANNULE ET REMPLACE) — en pratique une
  # seule à la fois, mais has_many au cas où une même commande serait modifiée
  # plusieurs fois (chaque nouvelle version modifie la précédente, pas
  # forcément l'originale).
  has_many :revisions, class_name: "Order", foreign_key: :modifies_order_id, inverse_of: :modifies_order
  has_many :order_lines, dependent: :destroy
  has_many :products, through: :order_lines

  before_create :generate_approval_token
  before_create :generate_reception_token

  def pending_approval? = approval_status == "pending_approval"
  def approved?         = approval_status == "approved"
  def refused?          = approval_status == "refused"
  def reception_confirmed? = reception_confirmed_at.present?
  def cancelled?         = cancelled_at.present?
  def superseded?        = revisions.exists?
  # Une commande annulée, ou remplacée par une version plus récente (ANNULE ET
  # REMPLACE), ne doit plus compter dans les totaux du reporting/dashboard —
  # elle reste néanmoins visible dans l'historique complet, avec une annotation.
  def excluded_from_reporting? = cancelled? || superseded?

  # Nom du chantier saisi à la commande (stocké dans les notes, pas de clé
  # étrangère : « Chantier: <nom> | Délai souhaité: … »).
  def self.chantier_name_of(notes)
    notes.to_s[/Chantier:\s*([^|]+)/, 1]&.strip
  end

  def chantier_name = self.class.chantier_name_of(notes)

  def self.for_chantier_names(names)
    wanted = names.to_set
    ids = pluck(:id, :notes).filter_map { |id, notes| id if wanted.include?(chantier_name_of(notes)) }
    where(id: ids)
  end

  # Commandes qu'un utilisateur a le droit de voir : toutes pour un admin,
  # sinon uniquement celles des chantiers qui lui sont visibles
  # (Chantier.visible_to : e-mail du fiche chantier, secteur, ou affectation
  # explicite Admin > Utilisateurs), quel que soit l'auteur de la commande.
  # Environnement test (admin) et production ne se mélangent jamais : chacun a
  # son Dashboard et sa numérotation.
  def self.in_environment(test)
    where(test_order: test ? true : false)
  end

  def self.visible_to(user)
    return all if user&.admin?
    return none unless user

    for_chantier_names(Chantier.visible_to(user).pluck(:nom))
  end

  # Texte de recherche d'une commande (sans accents ni casse) : numéro,
  # fournisseur, chantier, auteur et, pour chaque ligne, référence + nom d'article.
  def search_text
    parts = [ number, supplier&.name, chantier_name, user&.full_name ]
    order_lines.each { |l| parts << l.product&.reference << l.product&.name }
    Chantier.name_tokens(parts.compact.join(" ")).join(" ")
  end

  # Recherche libre (Dashboard) : tous les mots saisis doivent se retrouver
  # (début ou milieu de mot, sans accents ni casse) dans la commande — nom ou
  # référence d'un de ses articles, n° de commande, fournisseur, chantier…
  # Porte sur les 3'000 commandes les plus récentes du périmètre courant.
  def self.matching_query(query)
    words = Chantier.name_tokens(query)
    return all if words.empty?

    ids = includes(:supplier, :user, order_lines: :product).order(created_at: :desc).limit(3000)
            .select { |o| text = o.search_text; words.all? { |w| text.include?(w) } }.map(&:id)
    where(id: ids)
  end

  def total
    order_lines.sum(&:subtotal)
  end

  # Somme des frais annexes (peut être négative, ex. remise de volume BTest).
  # Ne vaut jamais 0 par confusion avec "aucun frais" : grand_total reste
  # correct même si extra_charges est vide ou absent (commandes antérieures à
  # l'ajout de cette colonne).
  def extra_charges_total
    (extra_charges || []).sum { |c| c["amount"].to_f }
  end

  def grand_total
    total + extra_charges_total
  end

  private

  def generate_approval_token
    self.approval_token = SecureRandom.urlsafe_base64(32)
  end

  # Separate from approval_token: this one is handed to the supplier (in the
  # order e-mail) so they can confirm reception, while approval_token is only
  # ever sent to the internal N+1 approver — sharing one token between the two
  # would let a supplier reach the internal approve/refuse pages.
  def generate_reception_token
    self.reception_token = SecureRandom.urlsafe_base64(32)
  end

  before_create :set_number

  # Also used to preview the number a not-yet-created order will get (see
  # Api::OrdersController#next_number), so the "Vérifier et envoyer" step can
  # show/let the user edit the real subject before sending. Racy under
  # concurrent submissions — purely cosmetic if two land at once, since the
  # actual number is still assigned atomically by set_number on save.
  def self.next_number(test: false)
    if test
      last_seq = where(test_order: true).pluck(:number)
                   .filter_map { |n| n[/\AESHOP_TEST_(\d+)\z/, 1]&.to_i }.max || 0
      return "ESHOP_TEST_#{(last_seq + 1).to_s.rjust(2, '0')}"
    end

    last_seq = where("number LIKE 'ESHOP_INDUNI_%'").pluck(:number)
                 .filter_map { |n| n[/\AESHOP_INDUNI_(\d+)\z/, 1]&.to_i }.max || 0
    last_seq = [ last_seq, OrderNumberFloor.value ].max
    "ESHOP_INDUNI_#{(last_seq + 1).to_s.rjust(2, '0')}"
  end

  # "ANNULE ET REMPLACE" : la nouvelle commande reprend le numéro de celle
  # qu'elle modifie, suffixé "-V2" (puis "-V3", etc. si modifiée à nouveau) —
  # jamais un nouveau numéro de la séquence générale, pour que le fournisseur
  # reconnaisse immédiatement qu'il s'agit de la même commande corrigée.
  def self.next_version_number(original_order)
    base = original_order.number.to_s.sub(/-V\d+\z/, "")
    versions = where("number LIKE ?", "#{base}-V%").pluck(:number)
                 .filter_map { |n| n[/\A#{Regexp.escape(base)}-V(\d+)\z/, 1]&.to_i }
    "#{base}-V#{(versions.max || 1) + 1}"
  end

  def set_number
    self.number = modifies_order ? self.class.next_version_number(modifies_order) : self.class.next_number(test: test_order)
  end
end
