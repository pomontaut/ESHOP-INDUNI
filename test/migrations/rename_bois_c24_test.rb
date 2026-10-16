require "test_helper"
require Rails.root.join("db/migrate/20261016150000_rename_bois_c24_to_plateau_bois_c24")

class RenameBoisC24Test < ActiveSupport::TestCase
  def run_migration = ActiveRecord::Migration.suppress_messages { RenameBoisC24ToPlateauBoisC24.new.up }

  test "renames the Bois C24 rubrique and article names, keeps references, and is idempotent" do
    hgc = Supplier.create!(name: "HG COMMERCIALE")
    leuba = Supplier.create!(name: "Leuba HIAG")
    a = Product.create!(supplier: hgc, reference: "127483", name: "Bois C24 50x300x4000 mm", famille: "Bois & Coffrage", sous_famille: "Bois C24")
    b = Product.create!(supplier: leuba, reference: "127483", name: "Bois C24 50x300x4000 mm", famille: "Bois & Coffrage", sous_famille: "Bois C24")
    stray = Product.create!(supplier: hgc, reference: "X1", name: "Bois C24 60x200", famille: "Bois & Coffrage", sous_famille: "Divers")
    other = Product.create!(supplier: hgc, reference: "X2", name: "Lambourde 50x80", famille: "Bois & Coffrage", sous_famille: "Lambourdes")

    2.times { run_migration }

    [ a, b ].each do |p|
      p.reload
      assert_equal "Plateau bois C24 50x300x4000 mm", p.name
      assert_equal "Plateau bois C24", p.sous_famille
      assert_equal "127483", p.reference
    end
    assert_equal "Plateau bois C24 60x200", stray.reload.name
    assert_equal "Divers", stray.sous_famille
    assert_equal "Lambourde 50x80", other.reload.name
  end

  test "the seed catalog no longer carries the old Bois C24 label" do
    items = JSON.parse(File.read(Rails.root.join("db/seed_data/catalog_products.json")))
    assert_empty items.select { |i| i["sousFamille"] == "Bois C24" || i["designation"].to_s.start_with?("Bois C24") }
    assert_operator items.count { |i| i["sousFamille"] == "Plateau bois C24" }, :>=, 1
  end
end
