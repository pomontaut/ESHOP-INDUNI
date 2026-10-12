require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "next_number ignores version-suffixed numbers when computing the next sequential number" do
    supplier = Supplier.create!(name: "Fournisseur test", email: "commandes@fournisseur.ch")
    original = Order.create!(supplier: supplier, order_date: Date.current)
    seq = original.number[/\AESHOP_INDUNI_(\d+)\z/, 1].to_i
    # Son numéro de version se termine par le chiffre "2" (…-V2) : ne doit
    # jamais être confondu avec une séquence "2" par next_number.
    Order.create!(supplier: supplier, order_date: Date.current, modifies_order: original)

    assert_equal "ESHOP_INDUNI_#{(seq + 1).to_s.rjust(2, '0')}", Order.next_number
  end

  test "a new order modifying another reuses its number suffixed -V2 instead of the general sequence" do
    supplier = Supplier.create!(name: "Fournisseur test", email: "commandes@fournisseur.ch")
    original = Order.create!(supplier: supplier, order_date: Date.current)

    revision = Order.create!(supplier: supplier, order_date: Date.current, modifies_order: original)

    assert_equal "#{original.number}-V2", revision.number
  end

  test "modifying a V2 a second time produces V3, based on the original's base number" do
    supplier = Supplier.create!(name: "Fournisseur test", email: "commandes@fournisseur.ch")
    original = Order.create!(supplier: supplier, order_date: Date.current)
    v2 = Order.create!(supplier: supplier, order_date: Date.current, modifies_order: original)

    v3 = Order.create!(supplier: supplier, order_date: Date.current, modifies_order: v2)

    assert_equal "#{original.number}-V3", v3.number
  end

  test "an order is superseded once another order declares modifying it, and excluded from reporting" do
    supplier = Supplier.create!(name: "Fournisseur test", email: "commandes@fournisseur.ch")
    original = Order.create!(supplier: supplier, order_date: Date.current)
    assert_not original.superseded?
    assert_not original.excluded_from_reporting?

    Order.create!(supplier: supplier, order_date: Date.current, modifies_order: original)

    assert original.reload.superseded?
    assert original.excluded_from_reporting?
  end

  test "a cancelled order is excluded from reporting" do
    supplier = Supplier.create!(name: "Fournisseur test", email: "commandes@fournisseur.ch")
    order = Order.create!(supplier: supplier, order_date: Date.current)
    assert_not order.cancelled?

    order.update!(cancelled_at: Time.current)

    assert order.cancelled?
    assert order.excluded_from_reporting?
  end
end
