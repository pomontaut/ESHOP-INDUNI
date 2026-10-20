require "test_helper"
require Rails.root.join("db/migrate/20261020100000_leuba_hiag_tarif_oct_2026_et_nettoyage_bois")

class LeubaHiagTarifOct2026Test < ActiveSupport::TestCase
  def items = JSON.parse(File.read(Rails.root.join("db/seed_data/catalog_products.json")))

  test "seed : nouveaux prix Leuba HIAG, nouvelles références, plus de plateau 50x300 ni de panneaux filmés" do
    leuba = items.select { |i| i["catalog"] == "Leuba HIAG" }
    assert_equal 811.62, leuba.find { |i| i["article"] == "127484" }["prix"]
    assert_equal 6.48, leuba.find { |i| i["article"] == "137493" }["prix"]
    assert_equal 33.0, leuba.find { |i| i["article"] == "HIAG-PIQUET-30x30x250" }["prix"]
    assert_equal 14.76, leuba.find { |i| i["article"] == "HIAG-CHABOURY-3850x1000" }["prix"]
    assert_empty items.select { |i| i["article"] == "127483" }
    assert_empty items.select { |i| i["designation"].to_s =~ /film/i }
    assert_equal %w[104629 104662], leuba.select { |i| i["sousFamille"] == "Accessoires" }.map { |i| i["article"] }.sort
  end

  test "migration supprime le plateau 50x300 et les filmés, garde un article déjà commandé hors catalogue" do
    leuba = Supplier.create!(name: "Leuba HIAG")
    hgc = Supplier.create!(name: "HG COMMERCIALE")
    plateau = Product.create!(supplier: leuba, reference: "127483", name: "Plateau bois C24 50x300x4000 mm", unit_price: 987.84, famille: "Bois & Coffrage", sous_famille: "Plateau bois C24")
    plateau_hgc = Product.create!(supplier: hgc, reference: "127483", name: "Plateau bois C24 50x300x4000 mm", unit_price: 392, famille: "Bois & Coffrage")
    filme = Product.create!(supplier: hgc, reference: "100071954", name: "Pann. contreplaqué bouleau film/film 220g 6.5mm", unit_price: 42.98, famille: "Bois")
    autre = Product.create!(supplier: leuba, reference: "127484", name: "Planche de coffrage 27x150x4000 mm", unit_price: 811.62, famille: "Bois & Coffrage")

    ActiveRecord::Migration.suppress_messages { LeubaHiagTarifOct2026EtNettoyageBois.new.up }

    assert_not Product.exists?(plateau.id)
    assert_not Product.exists?(plateau_hgc.id)
    assert_not Product.exists?(filme.id)
    assert Product.exists?(autre.id)
  end
end
