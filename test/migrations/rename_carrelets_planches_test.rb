require "test_helper"
require Rails.root.join("db/migrate/20261016170000_rename_carrelets_planches_to_planche")

class RenameCarreletsPlanchesTest < ActiveSupport::TestCase
  test "renames the rubrique and article names to Planche de coffrage, idempotently, without touching real carrelets" do
    s = Supplier.create!(name: "Leuba HIAG")
    a = Product.create!(supplier: s, reference: "127484", name: "Carrelets / planches de coffrage 27x150x4000 mm", famille: "Bois & Coffrage", sous_famille: "Carrelets / planches de coffrage")
    c80 = Product.create!(supplier: s, reference: "127466", name: "Carrelets / planches de coffrage 80x120x4000 mm", famille: "Bois & Coffrage", sous_famille: "Carrelets / planches de coffrage")
    carrelet = Product.create!(supplier: s, reference: "C1", name: "Carrelet sapin/épicéa brut CH 80x120mm L4000mm", famille: "Bois & Coffrage", sous_famille: "Divers")

    2.times { ActiveRecord::Migration.suppress_messages { RenameCarreletsPlanchesToPlanche.new.up } }

    assert_equal "Planche de coffrage 27x150x4000 mm", a.reload.name
    assert_equal "Planches de coffrage", a.sous_famille
    assert_equal "127484", a.reference
    assert_equal [ "Carrelet 80x120x4000 mm", "Carrelets" ], [ c80.reload.name, c80.sous_famille ]
    assert_equal "Carrelet sapin/épicéa brut CH 80x120mm L4000mm", carrelet.reload.name
  end

  test "seed catalog and front menu no longer use « Carrelets / planches de coffrage »" do
    items = JSON.parse(File.read(Rails.root.join("db/seed_data/catalog_products.json")))
    assert_empty items.select { |i| i["sousFamille"] == "Carrelets / planches de coffrage" || i["designation"].to_s.start_with?("Carrelets / planches") }
    assert_not_includes File.read(Rails.root.join("public/catalogue.html")), "'Carrelets / planches de coffrage'"
  end
end
