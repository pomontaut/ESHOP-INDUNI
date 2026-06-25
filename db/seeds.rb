# Clear existing data
OrderLine.destroy_all
Order.destroy_all
Product.destroy_all
Supplier.destroy_all

# Create suppliers
s1 = Supplier.create!(
  name: "TechSupply SA",
  email: "commandes@techsupply.ch",
  phone: "+41 21 123 45 67",
  address: "Rue de la Gare 1\n1000 Lausanne"
)

s2 = Supplier.create!(
  name: "Bureau Express",
  email: "orders@bureauexpress.ch",
  phone: "+41 22 987 65 43",
  address: "Avenue du Mont-Blanc 5\n1201 Genève"
)

s3 = Supplier.create!(
  name: "Matériaux Pro",
  email: "info@materiauxpro.ch",
  phone: "+41 31 456 78 90",
  address: "Bundesplatz 3\n3001 Berne"
)

# Create products
p1 = Product.create!(name: "Ordinateur portable Dell XPS", reference: "DELL-XPS-001", unit_price: 1299.00, supplier: s1)
p2 = Product.create!(name: "Écran 24 pouces Full HD", reference: "ECRAN-24FHD", unit_price: 349.00, supplier: s1)
p3 = Product.create!(name: "Clavier mécanique", reference: "KB-MECA-01", unit_price: 89.50, supplier: s1)
p4 = Product.create!(name: "Souris ergonomique", reference: "MOUSE-ERGO", unit_price: 65.00, supplier: s1)
p5 = Product.create!(name: "Ramette papier A4 500f", reference: "PAP-A4-500", unit_price: 6.90, supplier: s2)
p6 = Product.create!(name: "Stylos bille bleu x10", reference: "STYLO-BL-10", unit_price: 4.50, supplier: s2)
p7 = Product.create!(name: "Classeur A4 8cm", reference: "CLASS-A4-8", unit_price: 3.20, supplier: s2)
p8 = Product.create!(name: "Câble réseau Cat6 5m", reference: "CAT6-5M", unit_price: 12.00, supplier: s3)

# Create sample order
order = Order.create!(
  supplier: s1,
  status: 'draft',
  order_date: Date.today,
  notes: "Commande urgente pour le nouveau bureau"
)

OrderLine.create!(order: order, product: p1, quantity: 2, unit_price: p1.unit_price)
OrderLine.create!(order: order, product: p2, quantity: 4, unit_price: p2.unit_price)

puts "Données de test créées avec succès!"
puts "#{Supplier.count} fournisseurs, #{Product.count} produits, #{Order.count} commandes"
