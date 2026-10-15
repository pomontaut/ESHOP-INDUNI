# Une ligne = « à telle date, ce produit a pris ce nouveau prix ». Jamais
# créée quand une mise à jour du catalogue laisse le prix inchangé.
class ProductPriceChange < ApplicationRecord
  belongs_to :product

  # Appelé par catalog:seed : `before` = { [supplier_id, reference] => prix }
  # relevé avant l'upsert en masse (qui contourne les callbacks de Product).
  # Enregistre les articles nouveaux et ceux dont le prix a réellement changé.
  def self.record_seed_changes(before)
    now = Time.current
    rows = Product.pluck(:id, :supplier_id, :reference, :unit_price).filter_map do |id, supplier_id, reference, price|
      next if price.nil?

      previous = before[[ supplier_id, reference ]]
      next if previous && previous.to_d == price.to_d

      { product_id: id, price: price, changed_at: now, created_at: now, updated_at: now }
    end
    rows.each_slice(500) { |slice| insert_all(slice) }
    rows.size
  end
end
