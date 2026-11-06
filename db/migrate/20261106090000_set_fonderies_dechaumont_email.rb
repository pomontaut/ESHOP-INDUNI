# Fonderies Dechaumont : la fiche avait été créée sans e-mail (base fournisseurs vide) → l'envoi de la
# commande ESHOP_INDUNI_88 échouait faute de destinataire. Renseigne l'adresse commerciale, sans écraser
# une adresse déjà saisie à la main dans Admin > Fournisseurs.
class SetFonderiesDechaumontEmail < ActiveRecord::Migration[8.0]
  EMAIL = "commercial@fonderies-dechaumont.com"

  class MSupplier < ActiveRecord::Base; self.table_name = "suppliers"; end

  def up
    MSupplier.where("lower(name) = ?", "fonderies dechaumont").where(email: [ nil, "" ]).update_all(email: EMAIL)
  end

  def down; end
end
