# Bibliothèque d'articles Induni : référence INDUNI (n° compta, segmentation
# 1-3) rattachée à l'article de chaque fournisseur (référence + désignation +
# unité de prix). Lecture admin seulement ; aucun prix n'est stocké ici.
class NomenclatureEntry < ApplicationRecord
  SEED_PATH = Rails.root.join("db/seed_data/nomenclature_induni.json")

  validates :induni_reference, :supplier_name, :supplier_reference, presence: true

  scope :ordered, -> { order(:n_compta, :induni_reference, :supplier_name) }

  # Idempotent et synchronisé : le JSON est la source de vérité (clé = référence INDUNI +
  # fournisseur + référence fournisseur). Crée/met à jour chaque ligne et supprime celles qui n'y
  # figurent plus (n° renumérotés, article retiré) — cette table n'a aucune clé étrangère.
  def self.seed_from_json!(path = SEED_PATH)
    return 0 unless File.exist?(path)

    items = JSON.parse(File.read(path))
    wanted = items.map { |it| [ it["induniReference"], it["supplierName"], it["supplierReference"] ] }.to_set
    transaction do
      find_each { |row| row.destroy! unless wanted.include?([ row.induni_reference, row.supplier_name, row.supplier_reference ]) }
      items.each do |it|
        row = find_or_initialize_by(induni_reference: it["induniReference"], supplier_name: it["supplierName"],
                                    supplier_reference: it["supplierReference"])
        row.update!(
          n_compta:             it["nCompta"],
          segmentation1:        it["segmentation1"],
          segmentation2:        it["segmentation2"],
          segmentation3:        it["segmentation3"],
          induni_designation:   it["induniDesignation"],
          supplier_designation: it["supplierDesignation"],
          price_unit:           it["priceUnit"],
          search_keywords:      it["searchKeywords"]
        )
      end
    end
    count
  end

  # Vrai si la référence fournisseur existe toujours au catalogue e-shop.
  def self.catalog_keys
    Product.joins(:supplier).pluck("suppliers.name", "products.reference").to_set
  end
end
