require "test_helper"

class BonDeCommandeTemplateTest < ActiveSupport::TestCase
  test "hides the unit price and montant for a confidential-pricing supplier's order" do
    supplier = Supplier.create!(name: "Fournisseur confidentiel", confidential_pricing: true, email: "commandes@fournisseur.ch")
    product = Product.create!(supplier: supplier, reference: "ART-CONF", name: "Article confidentiel", famille: "Adjuvants", unit_price: 1200.0, unite: "PCE")
    order = Order.create!(supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: X | Délai: Y")
    order.order_lines.create!(product: product, quantity: 2, unit_price: 1200.0)

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_includes html, "Conformément à nos accords cadre"
    assert_not_includes html, "1'200.00"
    assert_not_includes html, "2'400.00"
  end

  test "shows the real unit price and montant for a non-confidential supplier's order" do
    supplier = Supplier.create!(name: "Fournisseur ouvert", email: "commandes@fournisseur.ch")
    product = Product.create!(supplier: supplier, reference: "ART-OUVERT", name: "Article ouvert", famille: "Voirie", unit_price: 10.0, unite: "PCE")
    order = Order.create!(supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: X | Délai: Y")
    order.order_lines.create!(product: product, quantity: 3, unit_price: 10.0)

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_not_includes html, "Conformément à nos accords cadre"
    assert_includes html, "CHF 10.00"
    assert_includes html, "CHF 30.00"
  end
end
