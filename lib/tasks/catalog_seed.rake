namespace :catalog do
  # The real catalog/chantiers data is only ever created inside data-migration
  # `up` methods. That's fragile: on a fresh/empty database Rails' db:migrate
  # takes a "load db/schema.rb + stamp schema_migrations" shortcut instead of
  # replaying every migration's `up`, which silently skips all that seeding
  # (schema.rb only ever contains structure, never data). This task
  # idempotently (re)creates the essential reference data — suppliers,
  # catalog products, chantiers — so it can be run unconditionally on every
  # boot as a safety net, regardless of how the schema got there.
  desc "Idempotently (re)seed suppliers, catalog products and chantiers from db/seed_data"
  task seed: :environment do
    required_suppliers = {
      "HGC" => {
        email: "yannick.mace@hgc.ch", phone: "0041 22 343 85 50", fax: "0041 22 343 40 92",
        address: "Stauffacherquai 46", postal_code: "8022", city: "Zürich", country_code: "CH",
        supplier_number: "230977", ide_number: "CHE-105.836.561", payment_condition: "30 jours 2%"
      },
      "Canplast" => {
        email: "commandes@canplast.ch", phone: "0041 21 637 37 77", fax: "0041 21 637 37 78",
        address: "Route de Sollens 2B", postal_code: "1029", city: "Villars-Ste-Croix", country_code: "CH",
        supplier_number: "883849", ide_number: "CHE-106.016.827", payment_condition: "30 jours 5%"
      },
      "Leuba HIAG" => {
        email: "william.bouquet@leubahiag.ch", phone: "0041 58 470 66 66",
        address: "Planchettes 1", postal_code: "1032", city: "Romanel-s-Lausanne", country_code: "CH",
        supplier_number: "100123867", ide_number: "CHE-100.123.867", payment_condition: "30 jours 2%"
      },
      "CreaBeton" => {
        email: "commandes@creabeton.ch", phone: "0848 400 401",
        address: "Bohler 5", postal_code: "6221", city: "Rickenbach LU", country_code: "CH",
        supplier_number: "11947"
      },
      "MBT" => {
        email: "didier.hossmann@mbt-bautechnik.com"
      },
      "ALZO AG" => {
        email: "info@alzo.ch", phone: "041 500 50 16", fax: "041 500 50 17",
        address: "12 Unterleh", postal_code: "6300", city: "Zug", country_code: "CH"
      },
      "Soreval" => {
        email: "l.sogno@soreval.ch", phone: "+41 22 341 15 71",
        address: "10, Route de la Maison Carrée", postal_code: "1242", city: "Satigny", country_code: "CH"
      },
      # Coordonnées de commande non communiquées dans l'accord tarifaire fourni :
      # à compléter par un admin (fiche fournisseur) avant le premier envoi réel.
      "BTest" => {},
      "LCBE" => {
        email: "info@lcbe.ch", phone: "021 947 47 58",
        address: "Route de l'Industrie 43B", postal_code: "1615", city: "Bossonnens", country_code: "CH"
      }
    }.freeze

    Supplier.where(name: [ "Sika", "Alzo" ]).find_each do |supplier|
      supplier.products.delete_all
      supplier.destroy
    end

    # N'initialise les coordonnées que pour un fournisseur réellement nouveau :
    # sinon on écraserait à chaque redémarrage les modifications faites depuis
    # l'admin (email, adresse, etc.).
    required_suppliers.each do |name, attrs|
      supplier = Supplier.find_or_initialize_by(name: name)
      supplier.update!(attrs) if supplier.new_record?
    end

    # Correction ponctuelle : l'ancienne adresse de commande CreaBeton
    # (info@creabeton.ch) a été saisie avant que le bon contact ne soit connu.
    # On ne la corrige que si elle vaut encore exactement l'ancienne valeur,
    # pour ne jamais écraser une adresse modifiée depuis l'admin.
    Supplier.where(name: "CreaBeton", email: "info@creabeton.ch")
            .update_all(email: "commandes@creabeton.ch")

    # Correction ponctuelle : l'adresse de commande Soreval n'était pas connue
    # au moment de la création du fournisseur (seedé sans e-mail). On ne la
    # complète que si elle est encore vide, pour ne jamais écraser une
    # modification faite depuis l'admin.
    Supplier.where(name: "Soreval", email: [ nil, "" ])
            .update_all(email: "l.sogno@soreval.ch", phone: "+41 22 341 15 71",
                         address: "10, Route de la Maison Carrée", postal_code: "1242", city: "Satigny", country_code: "CH")

    catalog_path = Rails.root.join("db/seed_data/catalog_products.json")
    if File.exist?(catalog_path)
      supplier_ids = Supplier.where(name: required_suppliers.keys).pluck(:name, :id).to_h
      items = JSON.parse(File.read(catalog_path)).select { |it| supplier_ids.key?(it["catalog"]) }
      now = Time.current

      rows = items.map do |it|
        {
          supplier_id:       supplier_ids[it["catalog"]],
          reference:         it["article"],
          name:              it["designation"],
          unit_price:        it["prix"],
          descriptif:        it["descriptif"],
          unite:             it["unite"],
          famille:           it["famille"],
          sous_famille:      it["sousFamille"],
          sous_sous_famille: it["sousSousFamille"],
          icone:             it["icone"],
          image:             it["image"],
          equivalence_key:   it["equivalenceKey"].presence,
          qte_palette:       it["qtePalette"],
          poids_kg:          it["poids"],
          prix_m2:           it["prixM2"],
          manually_added:    false,
          created_at:        now,
          updated_at:        now
        }
      end.uniq { |r| [ r[:supplier_id], r[:reference] ] }

      rows.each_slice(500) do |slice|
        Product.upsert_all(slice, unique_by: :index_products_on_supplier_id_and_reference)
      end

      # HGC and Leuba HIAG sheets cover ~99% of the known catalog: treat them
      # as a full refresh (items missing from the current JSON are discontinued).
      # Products confirmed live from a devis import (manually_added: true)
      # aren't part of the JSON and are excluded from this cleanup, or every
      # deploy would silently wipe them out. A discontinued product referenced
      # by a past order is kept too (deleting it would violate the order_lines
      # foreign key and abort every subsequent boot, as happened in production).
      [ "HGC", "Leuba HIAG" ].each do |catalog|
        supplier_id = supplier_ids[catalog]
        next unless supplier_id

        current_refs = items.select { |it| it["catalog"] == catalog }.map { |it| it["article"] }.to_set
        Product.where(supplier_id: supplier_id, manually_added: false)
               .where.not(reference: current_refs.to_a)
               .where.not(id: OrderLine.select(:product_id))
               .delete_all
      end
    end

    # Chantiers are now managed by admins through /admin/chantiers, so this is
    # a one-time bootstrap (and a recovery net if the table is ever found
    # empty, e.g. after a schema-only DB reset) rather than a full refresh:
    # re-running it unconditionally would wipe out every admin edit on each
    # container boot.
    chantiers_path = Rails.root.join("db/seed_data/chantiers.json")
    if File.exist?(chantiers_path) && Chantier.count.zero?
      now = Time.current
      rows = JSON.parse(File.read(chantiers_path)).map do |it|
        it.slice(
          "nom", "contraintes_acces", "adresse", "npa", "ville", "carte_interactive",
          "technicien", "natel_technicien", "email_technicien",
          "contremaitre", "natel_contremaitre", "email_contremaitre",
          "chef_equipe", "natel_chef_equipe", "email_chef_equipe", "consortium"
        ).merge("created_at" => now, "updated_at" => now)
      end

      rows.each_slice(500) { |slice| Chantier.insert_all(slice) }
    end

    puts "catalog:seed — #{Supplier.count} fournisseurs, #{Product.count} produits, #{Chantier.count} chantiers"
  end
end
