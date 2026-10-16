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

  test "visible_to shows a user only the orders of the chantiers assigned to them, whoever placed the order" do
    supplier = Supplier.create!(name: "Fournisseur visibilité")
    user = users(:two)
    user.update!(admin: false, chantier_access_scope: "own")
    other = users(:one)
    assigned = Chantier.create!(nom: "12345-Affecté")
    Chantier.create!(nom: "99999-Autre")
    ChantierAssignment.create!(user: user, chantier: assigned)

    on_assigned_by_other = Order.create!(supplier: supplier, user: other, notes: "Chantier: 12345-Affecté | Délai souhaité: 20.10.2026")
    own_on_other_chantier = Order.create!(supplier: supplier, user: user, notes: "Chantier: 99999-Autre | Délai souhaité: 20.10.2026")
    Order.create!(supplier: supplier, user: other, notes: "Chantier: 99999-Autre | Délai souhaité: 20.10.2026")

    visible = Order.visible_to(user).to_a
    assert_equal [ on_assigned_by_other ], visible
    assert_not_includes visible, own_on_other_chantier
    assert_equal Order.count, Order.visible_to(other.tap { |u| u.update!(admin: true) }).count
    assert_equal 0, Order.visible_to(nil).count
  end

  test "next_number keeps counting after orders are purged (numbering floor)" do
    supplier = Supplier.create!(name: "Fournisseur numérotation")
    OrderLine.delete_all
    Order.delete_all
    3.times { Order.create!(supplier: supplier, notes: "Chantier: X | Délai souhaité: Y") }
    assert_equal "ESHOP_INDUNI_04", Order.next_number

    OrderNumberFloor.raise_to!(3)
    OrderLine.delete_all
    Order.delete_all
    assert_equal "ESHOP_INDUNI_04", Order.next_number

    OrderNumberFloor.reset!
    assert_equal "ESHOP_INDUNI_01", Order.next_number
  end
end
