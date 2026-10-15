require "test_helper"

class SupplierMergerTest < ActiveSupport::TestCase
  setup do
    @old = Supplier.create!(name: "HG COMMERCIALE", supplier_number: "230977", address: "Stauffacherquai 46")
    @new = Supplier.create!(name: "HGC", email: "yannick.mace@hgc.ch")
  end

  def make(supplier, ref, name, updated_at, **attrs)
    Product.create!({ supplier: supplier, reference: ref, name: name, unit_price: 1, updated_at: updated_at }.merge(attrs))
  end

  test "merges HGC into HG COMMERCIALE, newest product wins per reference, no duplicates" do
    make(@old, "A1", "ancien A1", 2.days.ago)
    make(@new, "A1", "nouveau A1", 1.day.ago)
    make(@old, "B2", "ancien B2 plus récent", 1.hour.ago)
    make(@new, "b2 ", "nouveau B2 plus ancien", 3.days.ago)
    make(@new, "C3", "seulement HGC", 1.day.ago)
    make(@old, "D4", "seulement HG COMMERCIALE", 1.day.ago)
    user = User.create!(email: "t.merge@induni.ch", first_name: "T", last_name: "M", password: "password123",
                        allowed_suppliers: [ "HGC", "Canplast" ])

    SupplierMerger.merge!(target_name: "HG COMMERCIALE", source_names: [ "HGC" ])

    assert_equal [ "HG COMMERCIALE" ], Supplier.where("name LIKE 'HG%'").pluck(:name)
    survivor = Supplier.find_by!(name: "HG COMMERCIALE")
    assert_equal "yannick.mace@hgc.ch", survivor.email
    assert_equal "230977", survivor.supplier_number
    products = survivor.products.index_by { |p| p.reference.upcase }
    assert_equal %w[A1 B2 C3 D4], products.keys.sort
    assert_equal "nouveau A1", products["A1"].name
    assert_equal "ancien B2 plus récent", products["B2"].name
    assert_equal [ "HG COMMERCIALE", "Canplast" ], user.reload.allowed_suppliers
  end

  test "keeps order lines of the discarded duplicate by repointing them" do
    old_a = make(@old, "A1", "ancien", 2.days.ago)
    make(@new, "A1", "nouveau", 1.day.ago)
    order = Order.create!(supplier: @old, order_date: Date.today, status: "pending")
    line = order.order_lines.create!(product: old_a, quantity: 1, unit_price: 1)

    SupplierMerger.merge!(target_name: "HG COMMERCIALE", source_names: [ "HGC" ])

    assert_equal "nouveau", line.reload.product.name
  end

  test "renames a lone HGC and is idempotent" do
    @old.destroy
    SupplierMerger.merge!(target_name: "HG COMMERCIALE", source_names: [ "HGC" ])
    SupplierMerger.merge!(target_name: "HG COMMERCIALE", source_names: [ "HGC" ])
    assert_equal [ "HG COMMERCIALE" ], Supplier.where("name LIKE 'HG%'").pluck(:name)
  end
end
