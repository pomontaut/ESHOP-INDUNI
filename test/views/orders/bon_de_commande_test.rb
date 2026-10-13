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

  test "falls back to the Induni depot address, and shows an em-dash for conducteur de travaux when none was entered and no chantier matches" do
    supplier = Supplier.create!(name: "Fournisseur ouvert", email: "commandes@fournisseur.ch")
    product = Product.create!(supplier: supplier, reference: "ART-OUVERT", name: "Article ouvert", famille: "Voirie", unit_price: 10.0, unite: "PCE")
    order = Order.create!(supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: X | Délai: Y")
    order.order_lines.create!(product: product, quantity: 1, unit_price: 10.0)

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_includes html, "Avenue des Grandes-Communes 6"
    assert_includes html, "Conducteur de travaux : —"
  end

  test "always shows the ordering user as the contact rédacteur de la commande, regardless of the conducteur de travaux" do
    supplier = Supplier.create!(name: "Fournisseur ouvert", email: "commandes@fournisseur.ch")
    product = Product.create!(supplier: supplier, reference: "ART-OUVERT", name: "Article ouvert", famille: "Voirie", unit_price: 10.0, unite: "PCE")
    order = Order.create!(
      supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: X | Délai: Y",
      conducteur_travaux: "Paul Dupont"
    )
    order.order_lines.create!(product: product, quantity: 1, unit_price: 10.0)

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_includes html, "Contact rédacteur de la commande :"
    assert_includes html, users(:one).full_name
    assert_includes html, users(:one).email
    assert_includes html, "Contact chantier :"
    assert_includes html, "Conducteur de travaux : Paul Dupont"
  end

  test "shows the ANNULE ET REMPLACE banner with the original order's number when modifying a previous order" do
    supplier = Supplier.create!(name: "Fournisseur ouvert", email: "commandes@fournisseur.ch")
    product = Product.create!(supplier: supplier, reference: "ART-OUVERT", name: "Article ouvert", famille: "Voirie", unit_price: 10.0, unite: "PCE")
    original = Order.create!(supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: X | Délai: Y")
    order = Order.create!(supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: X | Délai: Y", modifies_order: original)
    order.order_lines.create!(product: product, quantity: 1, unit_price: 10.0)

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_match(/Annule et remplace la commande N°\s*#{Regexp.escape(original.number)}/i, html)
  end

  test "shows no ANNULE ET REMPLACE banner for a regular order" do
    supplier = Supplier.create!(name: "Fournisseur ouvert", email: "commandes@fournisseur.ch")
    product = Product.create!(supplier: supplier, reference: "ART-OUVERT", name: "Article ouvert", famille: "Voirie", unit_price: 10.0, unite: "PCE")
    order = Order.create!(supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: X | Délai: Y")
    order.order_lines.create!(product: product, quantity: 1, unit_price: 10.0)

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_no_match(/Annule et remplace/i, html)
  end

  test "no longer shows the old 'Informations complémentaires sur le chantier' block, superseded by Contact chantier" do
    Chantier.create!(nom: "12601-Halle des Rouettes", contremaitre: "PESSOA FRANCISCO Joni", technicien: "Jean Dupont")
    supplier = Supplier.create!(name: "Fournisseur ouvert", email: "commandes@fournisseur.ch")
    product = Product.create!(supplier: supplier, reference: "ART-OUVERT", name: "Article ouvert", famille: "Voirie", unit_price: 10.0, unite: "PCE")
    order = Order.create!(supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: 12601-Halle des Rouettes | Délai: Y")
    order.order_lines.create!(product: product, quantity: 1, unit_price: 10.0)

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_no_match(/Informations complémentaires sur le chantier/, html)
  end

  test "shows a single total amount in the totals box, never a lone CHF in the Prix unit. column" do
    supplier = Supplier.create!(name: "Fournisseur ouvert", email: "commandes@fournisseur.ch")
    product = Product.create!(supplier: supplier, reference: "ART-OUVERT", name: "Article ouvert", famille: "Voirie", unit_price: 10.0, unite: "PCE")
    order = Order.create!(supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: X | Délai: Y")
    order.order_lines.create!(product: product, quantity: 3, unit_price: 10.0)

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_match(/<div class="sum total">\s*<span>TOTAL H\.T\.<\/span>\s*<b>CHF 30\.00<\/b>\s*<\/div>/m, html)
    assert_no_match(/<td>CHF <\/td>|<td><\/td>/m, html)
  end

  test "persists and shows the per-supplier delivery/transport extra charges computed client-side, and adds them to the grand total" do
    supplier = Supplier.create!(name: "Canplast", email: "commandes@canplast.ch")
    product = Product.create!(supplier: supplier, reference: "ART-CANPLAST", name: "Tuyau PVC", famille: "Drainage", unit_price: 100.0, unite: "PCE")
    order = Order.create!(
      supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: X | Délai: Y",
      extra_charges: [ { "label" => "Conditions cadre — RPLP 2.2%", "amount" => 2.20 }, { "label" => "Livraison Canplast — Zone 2", "amount" => 210.0 } ]
    )
    order.order_lines.create!(product: product, quantity: 1, unit_price: 100.0)

    assert_equal 312.20, order.grand_total

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_includes html, "Conditions cadre — RPLP 2.2%"
    assert_includes html, "CHF 2.20"
    assert_includes html, "Livraison Canplast — Zone 2"
    assert_includes html, "CHF 210.00"
    assert_match(/<div class="sum total">\s*<span>TOTAL H\.T\.<\/span>\s*<b>CHF 312\.20<\/b>\s*<\/div>/m, html)
  end

  test "never shows the extra charges breakdown for a confidential-pricing supplier" do
    supplier = Supplier.create!(name: "Fournisseur confidentiel", confidential_pricing: true, email: "commandes@fournisseur.ch")
    product = Product.create!(supplier: supplier, reference: "ART-CONF", name: "Article confidentiel", famille: "Adjuvants", unit_price: 1200.0, unite: "PCE")
    order = Order.create!(
      supplier: supplier, user: users(:one), order_date: Date.current, notes: "Chantier: X | Délai: Y",
      extra_charges: [ { "label" => "Transport fixe", "amount" => 50.0 } ]
    )
    order.order_lines.create!(product: product, quantity: 1, unit_price: 1200.0)

    html = ApplicationController.render(template: "orders/bon_de_commande", layout: false, assigns: { order: order })

    assert_not_includes html, "Transport fixe"
    assert_not_includes html, "CHF 50.00"
  end
end
