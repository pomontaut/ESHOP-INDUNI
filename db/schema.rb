# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_30_260000) do
  create_table "canplast_surcharges", force: :cascade do |t|
    t.string "codes", null: false
    t.datetime "created_at", null: false
    t.date "effective_date", null: false
    t.string "label", null: false
    t.string "source"
    t.decimal "surcharge_pct", precision: 6, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["codes", "effective_date"], name: "index_canplast_surcharges_on_codes_and_effective_date", unique: true
  end

  create_table "chantier_assignments", force: :cascade do |t|
    t.integer "chantier_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["chantier_id"], name: "index_chantier_assignments_on_chantier_id"
    t.index ["user_id", "chantier_id"], name: "index_chantier_assignments_on_user_id_and_chantier_id", unique: true
    t.index ["user_id"], name: "index_chantier_assignments_on_user_id"
  end

  create_table "chantier_contacts", force: :cascade do |t|
    t.integer "chantier_id", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "natel"
    t.string "nom"
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["chantier_id", "role"], name: "index_chantier_contacts_on_chantier_id_and_role"
    t.index ["chantier_id"], name: "index_chantier_contacts_on_chantier_id"
    t.index ["email"], name: "index_chantier_contacts_on_email"
  end

  create_table "chantiers", force: :cascade do |t|
    t.string "adresse"
    t.string "canton"
    t.string "carte_interactive"
    t.string "chef_equipe"
    t.string "conducteur_travaux"
    t.boolean "consortium", default: false, null: false
    t.boolean "consortium_conflict", default: false, null: false
    t.string "contact_livraison"
    t.text "contraintes_acces"
    t.string "contremaitre"
    t.datetime "created_at", null: false
    t.string "email_chef_equipe"
    t.string "email_conducteur_travaux"
    t.string "email_contremaitre"
    t.string "email_livraison"
    t.string "email_technicien"
    t.string "natel_chef_equipe"
    t.string "natel_conducteur_travaux"
    t.string "natel_contremaitre"
    t.string "natel_livraison"
    t.string "natel_technicien"
    t.string "nom", null: false
    t.string "npa"
    t.string "secteur"
    t.string "technicien"
    t.datetime "updated_at", null: false
    t.string "ville"
    t.index ["email_chef_equipe"], name: "index_chantiers_on_email_chef_equipe"
    t.index ["email_conducteur_travaux"], name: "index_chantiers_on_email_conducteur_travaux"
    t.index ["email_contremaitre"], name: "index_chantiers_on_email_contremaitre"
    t.index ["email_technicien"], name: "index_chantiers_on_email_technicien"
  end

  create_table "delivery_call_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "delivery_call_id", null: false
    t.integer "order_line_id", null: false
    t.decimal "quantity", precision: 14, scale: 3, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_call_id"], name: "index_delivery_call_lines_on_delivery_call_id"
    t.index ["order_line_id"], name: "index_delivery_call_lines_on_order_line_id"
  end

  create_table "delivery_calls", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.integer "order_id", null: false
    t.date "planned_on", null: false
    t.string "planned_time"
    t.text "slots"
    t.string "status", default: "planned", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["order_id"], name: "index_delivery_calls_on_order_id"
    t.index ["user_id"], name: "index_delivery_calls_on_user_id"
  end

  create_table "diesel_prices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "price", precision: 6, scale: 3, null: false
    t.datetime "updated_at", null: false
    t.date "week_start", null: false
    t.index ["week_start"], name: "index_diesel_prices_on_week_start", unique: true
  end

  create_table "eshop_metrics", force: :cascade do |t|
    t.integer "catalogs_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "equivalent_count", default: 0, null: false
    t.integer "induni_count", default: 0, null: false
    t.date "metric_date", null: false
    t.integer "photos_count", default: 0, null: false
    t.integer "references_count", default: 0, null: false
    t.string "source", default: "live", null: false
    t.datetime "updated_at", null: false
    t.index ["metric_date"], name: "index_eshop_metrics_on_metric_date", unique: true
  end

  create_table "nomenclature_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "induni_designation"
    t.string "induni_reference", null: false
    t.string "n_compta"
    t.string "price_unit"
    t.text "search_keywords"
    t.string "segmentation1"
    t.string "segmentation2"
    t.string "segmentation3"
    t.string "supplier_designation"
    t.string "supplier_name", null: false
    t.string "supplier_reference", null: false
    t.datetime "updated_at", null: false
    t.index ["induni_reference", "supplier_name", "supplier_reference"], name: "index_nomenclature_entries_on_induni_and_supplier", unique: true
  end

  create_table "order_lines", force: :cascade do |t|
    t.decimal "catalog_price"
    t.datetime "created_at", null: false
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity"
    t.decimal "unit_price"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_lines_on_order_id"
    t.index ["product_id"], name: "index_order_lines_on_product_id"
  end

  create_table "order_number_floors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "floor", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "orders", force: :cascade do |t|
    t.text "approval_comment"
    t.string "approval_status", default: "approved"
    t.string "approval_token"
    t.string "approver_email"
    t.datetime "cancelled_at"
    t.string "conducteur_travaux"
    t.string "contact"
    t.datetime "created_at", null: false
    t.text "delivery_address"
    t.datetime "email_sent_at"
    t.text "extra_charges"
    t.datetime "invoiced_at"
    t.integer "modifies_order_id"
    t.text "notes"
    t.string "number"
    t.date "order_date"
    t.string "phone"
    t.boolean "pickup", default: false, null: false
    t.datetime "reception_confirmed_at"
    t.string "reception_token"
    t.string "reception_type"
    t.string "relance_kind"
    t.datetime "relance_sent_at"
    t.text "sent_body"
    t.string "sent_cc"
    t.string "sent_subject"
    t.string "sent_to"
    t.string "status"
    t.integer "supplier_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["modifies_order_id"], name: "index_orders_on_modifies_order_id"
    t.index ["reception_token"], name: "index_orders_on_reception_token", unique: true
    t.index ["supplier_id"], name: "index_orders_on_supplier_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "product_price_changes", force: :cascade do |t|
    t.datetime "changed_at", null: false
    t.datetime "created_at", null: false
    t.decimal "price", null: false
    t.integer "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "changed_at"], name: "index_product_price_changes_on_product_id_and_changed_at"
    t.index ["product_id"], name: "index_product_price_changes_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "descriptif"
    t.string "equivalence_key"
    t.string "famille"
    t.string "fiche_url"
    t.string "icone"
    t.string "image"
    t.boolean "manually_added", default: false, null: false
    t.string "name"
    t.boolean "needs_classification", default: false, null: false
    t.decimal "poids_kg"
    t.decimal "prix_externe"
    t.decimal "prix_m2"
    t.string "qte_palette"
    t.string "reference"
    t.string "sous_famille"
    t.string "sous_sous_famille"
    t.string "stock_status"
    t.integer "supplier_id", null: false
    t.decimal "unit_price"
    t.string "unite"
    t.datetime "updated_at", null: false
    t.index ["equivalence_key"], name: "index_products_on_equivalence_key"
    t.index ["supplier_id", "reference"], name: "index_products_on_supplier_id_and_reference", unique: true
    t.index ["supplier_id"], name: "index_products_on_supplier_id"
  end

  create_table "projets", force: :cascade do |t|
    t.integer "chantier_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "nom", null: false
    t.string "numero"
    t.integer "responsable_id"
    t.string "statut", default: "en_cours", null: false
    t.datetime "updated_at", null: false
    t.index ["chantier_id"], name: "index_projets_on_chantier_id"
    t.index ["responsable_id"], name: "index_projets_on_responsable_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth_key"
    t.datetime "created_at", null: false
    t.text "endpoint"
    t.string "p256dh_key"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "reception_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "order_line_id", null: false
    t.decimal "quantity_accepted", precision: 14, scale: 3, default: "0.0", null: false
    t.decimal "quantity_received", precision: 14, scale: 3, default: "0.0", null: false
    t.integer "reception_id", null: false
    t.datetime "updated_at", null: false
    t.index ["order_line_id"], name: "index_reception_lines_on_order_line_id"
    t.index ["reception_id"], name: "index_reception_lines_on_reception_id"
  end

  create_table "reception_scans", force: :cascade do |t|
    t.integer "byte_size", default: 0, null: false
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.binary "data", null: false
    t.string "filename"
    t.integer "reception_id", null: false
    t.datetime "updated_at", null: false
    t.index ["reception_id"], name: "index_reception_scans_on_reception_id"
  end

  create_table "receptions", force: :cascade do |t|
    t.string "bl_number"
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "delivery_call_id"
    t.integer "order_id", null: false
    t.decimal "progress_percent", precision: 6, scale: 2
    t.date "received_on", null: false
    t.string "status", default: "accepte", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["delivery_call_id"], name: "index_receptions_on_delivery_call_id"
    t.index ["order_id"], name: "index_receptions_on_order_id"
    t.index ["user_id"], name: "index_receptions_on_user_id"
  end

  create_table "seance_lancements", force: :cascade do |t|
    t.text "actions"
    t.decimal "budget_cible", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.date "date_seance"
    t.text "decisions"
    t.string "lieu"
    t.text "participants"
    t.text "perimetre"
    t.integer "projet_id", null: false
    t.boolean "realisee", default: false, null: false
    t.text "risques"
    t.text "strategie_achat"
    t.datetime "updated_at", null: false
    t.index ["projet_id"], name: "index_seance_lancements_on_projet_id", unique: true
  end

  create_table "search_agent_messages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_search_agent_messages_on_created_at"
  end

  create_table "search_memories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.string "induni_reference"
    t.string "kind", null: false
    t.string "note"
    t.boolean "one_way", default: false, null: false
    t.string "source", default: "chat", null: false
    t.string "status", default: "active", null: false
    t.string "supplier_name"
    t.string "supplier_reference"
    t.string "target_label"
    t.string "term"
    t.datetime "updated_at", null: false
    t.text "value", null: false
    t.index ["kind", "status"], name: "index_search_memories_on_kind_and_status"
  end

  create_table "suppliers", force: :cascade do |t|
    t.text "address"
    t.decimal "approval_threshold", precision: 10, scale: 2
    t.string "city"
    t.boolean "confidential_pricing", default: false, null: false
    t.string "country_code"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "email_fribourg"
    t.string "email_geneve"
    t.string "email_jura"
    t.string "email_secondaire"
    t.string "email_valais"
    t.string "email_vaud"
    t.string "fax"
    t.string "ide_number"
    t.boolean "inactive", default: false
    t.string "name"
    t.string "payment_condition"
    t.string "phone"
    t.string "postal_code"
    t.string "responsable_achat"
    t.string "supplier_number"
    t.datetime "updated_at", null: false
    t.text "visible_cantons"
    t.text "visible_sectors"
  end

  create_table "usage_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "kind", null: false
    t.datetime "occurred_at", null: false
    t.datetime "updated_at", null: false
    t.integer "usage_session_id"
    t.integer "user_id", null: false
    t.index ["occurred_at", "user_id"], name: "index_usage_events_on_occurred_at_and_user_id"
    t.index ["usage_session_id"], name: "index_usage_events_on_usage_session_id"
  end

  create_table "usage_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "emailed_at"
    t.date "report_date", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.index ["report_date"], name: "index_usage_reports_on_report_date", unique: true
  end

  create_table "usage_sessions", force: :cascade do |t|
    t.integer "active_seconds", default: 0, null: false
    t.integer "clicks", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "last_seen_at", null: false
    t.datetime "started_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["token"], name: "index_usage_sessions_on_token", unique: true
    t.index ["user_id", "started_at"], name: "index_usage_sessions_on_user_id_and_started_at"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false
    t.text "allowed_suppliers"
    t.string "approver_email"
    t.boolean "can_create_orders", default: false, null: false
    t.boolean "can_create_users", default: false, null: false
    t.boolean "can_enable_alerts", default: true, null: false
    t.boolean "can_generic_order", default: false, null: false
    t.boolean "can_import_quote", default: false, null: false
    t.boolean "can_modify_orders", default: false, null: false
    t.boolean "can_read", default: true, null: false
    t.boolean "can_validate_orders", default: true, null: false
    t.boolean "can_view_analysis", default: false, null: false
    t.boolean "can_view_dashboard", default: false, null: false
    t.boolean "can_view_intelligence_buying", default: false, null: false
    t.boolean "can_view_market_indices", default: false, null: false
    t.boolean "can_view_nomenclature", default: false, null: false
    t.string "chantier_access_scope", default: "own", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name"
    t.string "job_function"
    t.string "last_name"
    t.boolean "must_change_password", default: false, null: false
    t.decimal "order_limit", precision: 10, scale: 2
    t.string "password_digest", null: false
    t.string "phone"
    t.string "sector"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "chantier_assignments", "chantiers"
  add_foreign_key "chantier_assignments", "users"
  add_foreign_key "chantier_contacts", "chantiers"
  add_foreign_key "order_lines", "orders"
  add_foreign_key "order_lines", "products"
  add_foreign_key "orders", "orders", column: "modifies_order_id", on_delete: :nullify
  add_foreign_key "orders", "suppliers"
  add_foreign_key "orders", "users"
  add_foreign_key "product_price_changes", "products", on_delete: :cascade
  add_foreign_key "products", "suppliers"
  add_foreign_key "projets", "chantiers", on_delete: :nullify
  add_foreign_key "projets", "users", column: "responsable_id", on_delete: :nullify
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "seance_lancements", "projets"
end
