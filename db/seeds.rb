# Clear existing data
OrderLine.destroy_all
Order.destroy_all
Product.destroy_all
Supplier.destroy_all

# Create suppliers
s1 = Supplier.create!(
  name: "TechParts SA",
  email: "commandes@techparts.ch",
  phone: "+41 22 123 45 67",
  address: "Route de la Technique 42\n1200 Genève"
)

s2 = Supplier.create!(
  name: "Bureau Express SARL",
  email: "orders@bureauexpress.ch",
  phone: "+41 21 987 65 43",
  address: "Avenue des Bureaux 15\n1000 Lausanne"
)

s3 = Supplier.create!(
  name: "MégaStock AG",
  email: "achats@megastock.ch",
  phone: "+41 44 555 00 11",
  address: "Industriestrasse 88\n8000 Zürich"
)

# Create products
p1 = Product.create!(name: "Câble USB-C 2m", reference: "CAB-USBC-2M", unit_price: 12.90, supplier: s1)
p2 = Product.create!(name: "Hub USB 4 ports", reference: "HUB-USB-4P", unit_price: 34.50, supplier: s1)
p3 = Product.create!(name: "Écran 24\" Full HD", reference: "ECR-24FHD", unit_price: 189.00, supplier: s1)
p4 = Product.create!(name: "Papier A4 500 feuilles", reference: "PAP-A4-500", unit_price: 6.90, supplier: s2)
p5 = Product.create!(name: "Stylo bille bleu (boîte 10)", reference: "STY-BB-10", unit_price: 8.50, supplier: s2)
p6 = Product.create!(name: "Cartouche imprimante HP 305", reference: "CART-HP305", unit_price: 18.90, supplier: s2)
p7 = Product.create!(name: "Clavier sans fil", reference: "CLV-WLESS", unit_price: 45.00, supplier: s3)
p8 = Product.create!(name: "Souris ergonomique", reference: "SOU-ERGO", unit_price: 39.90, supplier: s3)

# Create orders
o1 = Order.create!(
  supplier: s1,
  status: 'draft',
  order_date: Date.today,
  notes: "Livraison urgente requise"
)
OrderLine.create!(order: o1, product: p1, quantity: 5, unit_price: p1.unit_price)
OrderLine.create!(order: o1, product: p2, quantity: 2, unit_price: p2.unit_price)
OrderLine.create!(order: o1, product: p3, quantity: 1, unit_price: p3.unit_price)

o2 = Order.create!(
  supplier: s2,
  status: 'sent',
  order_date: Date.today - 3,
  notes: "Commande mensuelle fournitures"
)
OrderLine.create!(order: o2, product: p4, quantity: 10, unit_price: p4.unit_price)
OrderLine.create!(order: o2, product: p5, quantity: 3, unit_price: p5.unit_price)
OrderLine.create!(order: o2, product: p6, quantity: 4, unit_price: p6.unit_price)

o3 = Order.create!(
  supplier: s3,
  status: 'confirmed',
  order_date: Date.today - 7
)
OrderLine.create!(order: o3, product: p7, quantity: 3, unit_price: p7.unit_price)
OrderLine.create!(order: o3, product: p8, quantity: 3, unit_price: p8.unit_price)

puts "Seed terminé : #{Supplier.count} fournisseurs, #{Product.count} produits, #{Order.count} commandes"
