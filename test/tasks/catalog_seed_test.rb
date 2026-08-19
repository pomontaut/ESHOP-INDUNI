require "test_helper"

class CatalogSeedTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("catalog:seed")
  end

  test "catalog:seed preserves manually-added products for full-refresh suppliers" do
    run_seed

    hgc = Supplier.find_by!(name: "HGC")
    manual = Product.create!(
      supplier: hgc, reference: "TEST-MANUAL-999", name: "Article ajouté manuellement",
      unit_price: 1.0, famille: "Article générique", sous_famille: "Devis import",
      manually_added: true
    )

    run_seed

    assert Product.exists?(manual.id), "a manually_added product must survive catalog:seed's full refresh"
  ensure
    Product.where(reference: "TEST-MANUAL-999").delete_all
  end

  test "catalog:seed still discontinues real (non-manually-added) products missing from the JSON" do
    run_seed

    hgc = Supplier.find_by!(name: "HGC")
    orphan = Product.create!(
      supplier: hgc, reference: "TEST-ORPHAN-999", name: "Article discontinué",
      unit_price: 1.0, famille: "Test", manually_added: false
    )

    run_seed

    assert_not Product.exists?(orphan.id), "non-manually-added products missing from the JSON must still be cleaned up"
  ensure
    Product.where(reference: "TEST-ORPHAN-999").delete_all
  end

  test "catalog:seed keeps a discontinued product still referenced by an order line" do
    run_seed

    hgc = Supplier.find_by!(name: "HGC")
    ordered = Product.create!(
      supplier: hgc, reference: "TEST-ORDERED-999", name: "Article commandé puis discontinué",
      unit_price: 1.0, famille: "Test", manually_added: false
    )
    order = Order.create!(supplier: hgc, number: "TEST-999")
    OrderLine.create!(order: order, product: ordered, quantity: 1, unit_price: 1.0)

    run_seed

    assert Product.exists?(ordered.id), "a product referenced by an order_line must survive catalog:seed's full refresh"
  ensure
    order&.destroy
    Product.where(reference: "TEST-ORDERED-999").delete_all
  end

  private

  def run_seed
    Rake::Task["catalog:seed"].reenable
    Rake::Task["catalog:seed"].invoke
  end
end
