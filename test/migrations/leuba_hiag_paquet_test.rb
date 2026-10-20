require "test_helper"
require Rails.root.join("db/migrate/20261016160000_leuba_hiag_prices_per_paquet")

class LeubaHiagPaquetTest < ActiveSupport::TestCase
  def run_migration = ActiveRecord::Migration.suppress_messages { LeubaHiagPricesPerPaquet.new.up }

  test "converts Leuba HIAG m3 prices to a per-paquet price, leaves other suppliers and unparsable items alone, and is idempotent" do
    leuba = Supplier.create!(name: "Leuba HIAG")
    hgc = Supplier.create!(name: "HG COMMERCIALE")
    carrelet = Product.create!(supplier: leuba, reference: "127484", name: "Carrelets / planches de coffrage 27x150x4000 mm", unit_price: 317, unite: "m3", descriptif: "Pcs/pqt 150 · délai S", famille: "Bois & Coffrage")
    plateau = Product.create!(supplier: leuba, reference: "127483", name: "Plateau bois C24 50x300x4000 mm", unit_price: 392, unite: "m3", descriptif: "Pcs/pqt 42 · délai S", famille: "Bois & Coffrage")
    sans_donnee = Product.create!(supplier: leuba, reference: "999", name: "Bois sans dimensions", unit_price: 300, unite: "m3", descriptif: "délai S", famille: "Bois & Coffrage")
    au_m2 = Product.create!(supplier: leuba, reference: "137493", name: "Panneaux OSB 3 9x2500x1250 mm", unit_price: 6.3, unite: "m2", descriptif: "Pcs/pqt 100", famille: "Bois & Coffrage")
    chez_hgc = Product.create!(supplier: hgc, reference: "127484", name: "Carrelets / planches de coffrage 27x150x4000 mm", unit_price: 317, unite: "m3", descriptif: "Pcs/pqt 150", famille: "Bois & Coffrage")

    2.times { run_migration }

    assert_equal 811.62, carrelet.reload.unit_price.to_f      # 317 × 0.027×0.150×4 × 150 = 317 × 2.43
    assert_equal "paquet", carrelet.unite
    assert_includes carrelet.descriptif, "CHF 317.00/m³"
    assert_equal 1, carrelet.descriptif.scan("Prix au paquet").size, "pas de préfixe en double"
    assert_equal 987.84, plateau.reload.unit_price.to_f       # 392 × 2.52
    assert_equal [ 300.0, "m3" ], [ sans_donnee.reload.unit_price.to_f, sans_donnee.unite ]
    assert_equal [ 6.3, "m2" ], [ au_m2.reload.unit_price.to_f, au_m2.unite ]
    assert_equal [ 317.0, "m3" ], [ chez_hgc.reload.unit_price.to_f, chez_hgc.unite ]
  end

  test "seed catalog prices Leuba HIAG wood per paquet" do
    items = JSON.parse(File.read(Rails.root.join("db/seed_data/catalog_products.json"))).select { |i| i["catalog"] == "Leuba HIAG" }
    assert_empty items.select { |i| i["unite"] == "m3" }
    assert_equal 811.62, items.find { |i| i["article"] == "127484" }["prix"]
    assert_equal "paquet", items.find { |i| i["article"] == "127484" }["unite"]
  end
end
