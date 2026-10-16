# Une seule ligne : plus grand numéro de séquence déjà attribué, conservé même
# si les commandes sont supprimées (voir Order.next_number).
class OrderNumberFloor < ApplicationRecord
  def self.value = order(:id).first&.floor.to_i

  def self.raise_to!(sequence)
    row = order(:id).first || new
    row.floor = [ row.floor.to_i, sequence.to_i ].max
    row.save!
  end

  def self.reset!
    order(:id).first&.update!(floor: 0)
  end
end
