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

  test "reports the delivery contact, address and conducteur de travaux actually entered for this order" do
    supplier = Supplier.create!(name: "Fournisseur ouvert", email: "commandes@fournisseur.ch")
    product = Product.create!(supplier: supplier, reference: "ART-OUVERT", name: "Article ouvert", famille: "Voirie", unit_price: 10.0, unite: "PCE")
    order = Order.create!(
      supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: 12601-Halle des Rouettes | Délai: Y",
      contact: "PESSOA FRANCISCO Joni", phone: "+41765686536",
      delivery_address: "Chemin des Rouettes 30\n1214 Vernier", conducteur_travaux: "Pierre-Olivier Montaut"
    )
    order.order_lines.create!(product: product, quantity: 1, unit_price: 10.0)

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_includes html, "Pierre-Olivier Montaut"
    assert_includes html, "PESSOA FRANCISCO Joni"
    assert_includes html, "+41765686536"
    assert_includes html, "Chemin des Rouettes 30<br>1214 Vernier"
    assert_not_includes html, "Pierre-Olivier MONTAUT" # l'ancien texte figé, casse différente
  end

  test "falls back to the ordering user's name when no conducteur de travaux was entered, and to the Induni depot address" do
    supplier = Supplier.create!(name: "Fournisseur ouvert", email: "commandes@fournisseur.ch")
    product = Product.create!(supplier: supplier, reference: "ART-OUVERT", name: "Article ouvert", famille: "Voirie", unit_price: 10.0, unite: "PCE")
    order = Order.create!(supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: X | Délai: Y")
    order.order_lines.create!(product: product, quantity: 1, unit_price: 10.0)

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_includes html, users(:one).full_name
    assert_includes html, "Avenue des Grandes-Communes 6"
  end

  test "shows the chantier's own contremaître and technicien when a matching chantier exists" do
    Chantier.create!(nom: "12601-Halle des Rouettes", contremaitre: "PESSOA FRANCISCO Joni", technicien: "Jean Dupont")
    supplier = Supplier.create!(name: "Fournisseur ouvert", email: "commandes@fournisseur.ch")
    product = Product.create!(supplier: supplier, reference: "ART-OUVERT", name: "Article ouvert", famille: "Voirie", unit_price: 10.0, unite: "PCE")
    order = Order.create!(supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: 12601-Halle des Rouettes | Délai: Y")
    order.order_lines.create!(product: product, quantity: 1, unit_price: 10.0)

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_includes html, "Jean Dupont"
  end
end
