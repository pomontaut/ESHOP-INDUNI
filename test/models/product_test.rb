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

  test "seed catalog carries the HGC goutte pendante profile (botte de 40 pces = 100 m) next to the triangular profiles" do
    items = JSON.parse(File.read(Rails.root.join("db/seed_data/catalog_products.json"))).select { |i| i["catalog"] == "HG COMMERCIALE" }
    goutte = items.find { |i| i["article"] == "100013624" }
    assert_equal "Profil goutte pendante plastique 12mm L250cm 40pces", goutte["designation"]
    assert_equal [ 65.35, "botte", 8.4 ], [ goutte["prix"], goutte["unite"], goutte["poids"] ]
    assert_equal [ "Coffrage & Étaiement", "Coffrage", "Profils plastique" ], [ goutte["famille"], goutte["sousFamille"], goutte["sousSousFamille"] ]
    assert_equal 4, items.count { |i| i["sousSousFamille"] == "Profils plastique" }
  end

  test "every product image referenced by the seed catalog exists in public/images/products" do
    items = JSON.parse(File.read(Rails.root.join("db/seed_data/catalog_products.json")))
    refs = items.filter_map { |i| i["image"] }.select { |path| path.start_with?("/images/products/") }.uniq
    assert_operator refs.size, :>, 200
    missing = refs.reject { |path| File.exist?(Rails.root.join("public", path.delete_prefix("/"))) }
    assert_empty missing, "images référencées mais absentes : #{missing.first(5).join(', ')}"
  end
end
