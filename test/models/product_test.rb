require "test_helper"

class ProductTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "seed catalog carries the HGC triangular plastic profiles in Coffrage & Étaiement, priced per 100 m lot" do
    items = JSON.parse(File.read(Rails.root.join("db/seed_data/catalog_products.json")))
                .select { |i| i["catalog"] == "HG COMMERCIALE" && %w[100013524 100013526 100013528].include?(i["article"]) }
    assert_equal({ "100013524" => 47.41, "100013526" => 53.82, "100013528" => 79.87 }, items.to_h { |i| [ i["article"], i["prix"] ] })
    assert_equal [ [ "Coffrage & Étaiement", "Coffrage", "lot" ] ], items.map { |i| [ i["famille"], i["sousFamille"], i["unite"] ] }.uniq
    assert_match(/10x10mm L100m/, items.first["designation"])
  end
end
