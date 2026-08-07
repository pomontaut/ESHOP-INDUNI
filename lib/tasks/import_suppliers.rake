require "csv"

namespace :suppliers do
  desc "Import suppliers from CSV file: rake suppliers:import FILE=path/to/file.csv"
  task import: :environment do
    file = ENV["FILE"] || Rails.root.join("db/seeds/fournisseurs.csv")
    unless File.exist?(file)
      puts "File not found: #{file}"
      exit 1
    end

    imported = 0
    skipped = 0

    CSV.foreach(file, col_sep: ";", headers: true, encoding: "UTF-8") do |row|
      supplier_number = row["Numéro fournisseur"]&.strip
      name = row["Nom"]&.strip
      next if name.blank?

      address_parts = [
        row["Adresse l1"]&.strip,
        row["Adresse l2"]&.strip,
        row["Adresse l3"]&.strip,
        row["Numéro de rue"]&.strip
      ].reject(&:blank?).join(", ")

      supplier = Supplier.find_or_initialize_by(supplier_number: supplier_number)
      supplier.assign_attributes(
        name:               name,
        email:              row["E-mail"]&.strip,
        phone:              row["Téléphone"]&.strip,
        fax:                row["Fax"]&.strip,
        address:            address_parts,
        postal_code:        row["NPA"]&.strip,
        city:               row["Lieu"]&.strip,
        country_code:       row["Code Pays"]&.strip,
        ide_number:         row["Numéro IDE"]&.strip,
        payment_condition:  row["Condition de paiement"]&.strip,
        inactive:           row["Inactif"]&.strip == "Oui"
      )

      if supplier.save(validate: false)
        imported += 1
      else
        puts "Skipped #{name}: #{supplier.errors.full_messages.join(', ')}"
        skipped += 1
      end
    end

    puts "Import terminé: #{imported} fournisseurs importés, #{skipped} ignorés."
  end
end
