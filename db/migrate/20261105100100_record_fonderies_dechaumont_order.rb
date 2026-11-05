# Enregistre au Dashboard le bon de commande BC-425120 (Fonderies Dechaumont, chantier 35606 Amex Carouge,
# 27.10.2026) : prévisualisé puis transmis au fournisseur par un autre moyen, il n'avait jamais été
# enregistré par l'e-shop. Prix en EUR (devise du devis) ; cours EUR/CHF = dernier cours disponible de
# public/eurchf_rates.json (14.09.2026, indicatif, modifiable en base). Aucun e-mail n'est envoyé.
# Idempotent : ne fait rien si la commande existe déjà (repérée par sa référence dans le texte de transmission).
class RecordFonderiesDechaumontOrder < ActiveRecord::Migration[8.0]
  REF = "BC-425120"
  RATE = 0.944

  class MOrder < ActiveRecord::Base; self.table_name = "orders"; self.inheritance_column = nil; end

  def up
    return if MOrder.where("transmitted_via LIKE ?", "%#{REF}%").exists?

    supplier = (FournisseursBase.find_or_create_supplier("Fonderies Dechaumont") rescue nil) ||
               Supplier.find_or_create_by!(name: "Fonderies Dechaumont")
    user = User.where("lower(email) = ?", "pchabut@induni.ch").first
    day = Time.find_zone!("Europe/Zurich").local(2026, 10, 27, 12, 0)

    order = Order.new(
      supplier: supplier, user: user, status: "sent", approval_status: "approved",
      order_date: Date.new(2026, 10, 27),
      notes: "Chantier: 35606-Amex Carouge | Délai souhaité: 01.12.2026",
      contact: "MENDES LOUREIRO Ricardo", phone: "+41762407949",
      delivery_address: "43 Rue de Carouge\n1211 Genève", conducteur_travaux: "CHABUT Pierre",
      currency: "EUR", chf_rate: RATE,
      transmitted_via: "Transmise au fournisseur par un autre moyen (hors e-shop) — bon de commande #{REF} du 27.10.2026",
      created_at: day, updated_at: day
    )
    order.save!
    [
      [ "0106MATRICE", "Grille ronde D850 400KN OL600 à cadre design spécial", 15, 426.30 ],
      [ "01042000", "Participation outillage (fiche technique/Plan 3D, fabrication outillage, stockage et assurance), payable une seule fois à la 1ère commande", 1, 7434.00 ],
      [ "30991090", "Aquarl Akzo Nobel + Thermo FS, RAL au choix", 15, 254.88 ]
    ].each do |ref, name, qty, price|
      product = Product.find_or_create_by!(supplier: supplier, reference: ref) do |p|
        p.name = name; p.unit_price = price; p.unite = "UN"; p.famille = "Article générique"
        p.sous_famille = "Devis import"; p.descriptif = "Article générique (devis Fonderies Dechaumont)"
      end
      order.order_lines.create!(product: product, quantity: qty, unit_price: price)
    end
  end

  def down
    MOrder.where("transmitted_via LIKE ?", "%#{REF}%").find_each do |o|
      OrderLine.where(order_id: o.id).delete_all
      o.delete
    end
  end
end
