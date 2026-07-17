class SeedCoreSupplierData < ActiveRecord::Migration[8.1]
  CORE_SUPPLIERS = {
    "HGC" => {
      email: "yannick.mace@hgc.ch",
      phone: "0041 22 343 85 50",
      fax: "0041 22 343 40 92",
      address: "Stauffacherquai 46",
      postal_code: "8022",
      city: "Zürich",
      country_code: "CH",
      supplier_number: "230977",
      ide_number: "CHE-105.836.561",
      payment_condition: "30 jours 2%"
    },
    "Sika" => {
      email: "brugger.patrick@ch.sika.com",
      phone: "0041 1 436 40 40",
      address: "Tueffenwies 16-22",
      postal_code: "8048",
      city: "Zurich",
      country_code: "CH",
      supplier_number: "232631",
      payment_condition: "30 jours net"
    },
    "Canplast" => {
      email: "commandes@canplast.ch",
      phone: "0041 21 637 37 77",
      fax: "0041 21 637 37 78",
      address: "Route de Sollens 2B",
      postal_code: "1029",
      city: "Villars-Ste-Croix",
      country_code: "CH",
      supplier_number: "883849",
      ide_number: "CHE-106.016.827",
      payment_condition: "30 jours 5%"
    },
    "Alzo" => {
      email: "info@alzo.ch",
      phone: "0041 41 500 50 16",
      fax: "0041 41 500 50 17",
      address: "Unterleh 12",
      postal_code: "6300",
      city: "Zug",
      country_code: "CH",
      supplier_number: "966918",
      ide_number: "CHE-369.114.827",
      payment_condition: "30 jours net"
    },
    "Leuba HIAG" => {
      email: "william.bouquet@leubahiag.ch",
      phone: "0041 58 470 66 66",
      address: "Planchettes 1",
      postal_code: "1032",
      city: "Romanel-s-Lausanne",
      country_code: "CH",
      supplier_number: "100123867",
      ide_number: "CHE-100.123.867",
      payment_condition: "30 jours 2%"
    }
  }.freeze

  def up
    CORE_SUPPLIERS.each do |name, attrs|
      supplier = Supplier.find_or_initialize_by(name: name)
      supplier.update!(attrs)
    end
  end

  def down
    # Data fix only — no rollback of the supplier records themselves.
  end
end
