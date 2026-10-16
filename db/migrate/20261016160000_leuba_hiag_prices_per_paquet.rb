class LeubaHiagPricesPerPaquet < ActiveRecord::Migration[8.0]
  # Leuba HIAG : les articles tarifés au m³ (carrelets / planches de coffrage,
  # plateau bois C24) passent au PAQUET. Prix du paquet = prix au m³ × volume du
  # paquet (épaisseur × largeur × longueur × pièces par paquet, d'après la
  # désignation « 27x150x4000 mm » et « Pcs/pqt 150 »). Un article dont ces
  # données manquent est laissé tel quel. Idempotent : ne traite que l'unité m3.
  def up
    leuba = Supplier.find_by(name: "Leuba HIAG")
    return unless leuba

    Product.where(supplier_id: leuba.id).where("LOWER(unite) IN ('m3', 'm³')").find_each do |product|
      dims = product.name.to_s.tr(",", ".").match(/(\d+(?:\.\d+)?)\s*x\s*(\d+(?:\.\d+)?)\s*x\s*(\d+(?:\.\d+)?)\s*mm/i)
      pieces = product.descriptif.to_s[/Pcs\/pqt\s*(\d+)/i, 1]
      next if dims.nil? || pieces.nil? || product.unit_price.to_f <= 0

      volume = dims[1].to_f * dims[2].to_f * dims[3].to_f / 1e9 * pieces.to_i
      per_m3 = product.unit_price.to_f
      product.update_columns(
        unit_price: (per_m3 * volume).round(2),
        unite: "paquet",
        descriptif: "Prix au paquet (#{pieces} pcs = #{format('%.3f', volume)} m³, soit CHF #{format('%.2f', per_m3)}/m³) · #{product.descriptif}",
        updated_at: Time.current
      )
    end
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
