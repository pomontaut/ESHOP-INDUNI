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

ActiveRecord::Schema[8.1].define(version: 2026_08_20_095827) do
  create_table "chantiers", force: :cascade do |t|
    t.string "adresse"
    t.string "canton"
    t.string "carte_interactive"
    t.string "chef_equipe"
    t.boolean "consortium", default: false, null: false
    t.text "contraintes_acces"
    t.string "contremaitre"
    t.datetime "created_at", null: false
    t.string "email_chef_equipe"
    t.string "email_contremaitre"
    t.string "email_technicien"
    t.string "natel_chef_equipe"
    t.string "natel_contremaitre"
    t.string "natel_technicien"
    t.string "nom", null: false
    t.string "npa"
    t.string "technicien"
    t.datetime "updated_at", null: false
    t.string "ville"
    t.index ["email_chef_equipe"], name: "index_chantiers_on_email_chef_equipe"
    t.index ["email_contremaitre"], name: "index_chantiers_on_email_contremaitre"
    t.index ["email_technicien"], name: "index_chantiers_on_email_technicien"
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

  create_table "orders", force: :cascade do |t|
    t.text "approval_comment"
    t.string "approval_status", default: "approved"
    t.string "approval_token"
    t.string "approver_email"
    t.datetime "created_at", null: false
    t.integer "modifies_order_id"
    t.text "notes"
    t.string "number"
    t.date "order_date"
    t.datetime "reception_confirmed_at"
    t.string "reception_token"
    t.string "status"
    t.integer "supplier_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["modifies_order_id"], name: "index_orders_on_modifies_order_id"
    t.index ["reception_token"], name: "index_orders_on_reception_token", unique: true
    t.index ["supplier_id"], name: "index_orders_on_supplier_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "descriptif"
    t.string "equivalence_key"
    t.string "famille"
    t.string "icone"
    t.string "image"
    t.boolean "manually_added", default: false, null: false
    t.string "name"
    t.boolean "needs_classification", default: false, null: false
    t.decimal "poids_kg"
    t.decimal "prix_m2"
    t.string "qte_palette"
    t.string "reference"
    t.string "sous_famille"
    t.string "sous_sous_famille"
    t.integer "supplier_id", null: false
    t.decimal "unit_price"
    t.string "unite"
    t.datetime "updated_at", null: false
    t.index ["equivalence_key"], name: "index_products_on_equivalence_key"
    t.index ["supplier_id", "reference"], name: "index_products_on_supplier_id_and_reference", unique: true
    t.index ["supplier_id"], name: "index_products_on_supplier_id"
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

  create_table "suppliers", force: :cascade do |t|
    t.text "address"
    t.string "city"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "email_fribourg"
    t.string "email_geneve"
    t.string "email_jura"
    t.string "email_valais"
    t.string "email_vaud"
    t.string "fax"
    t.string "ide_number"
    t.boolean "inactive", default: false
    t.string "name"
    t.string "payment_condition"
    t.string "phone"
    t.string "postal_code"
    t.string "supplier_number"
    t.datetime "updated_at", null: false
    t.text "visible_cantons"
    t.text "visible_sectors"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false
    t.text "allowed_suppliers"
    t.string "approver_email"
    t.boolean "can_create_orders", default: false, null: false
    t.boolean "can_create_users", default: false, null: false
    t.boolean "can_generic_order", default: false, null: false
    t.boolean "can_import_quote", default: false, null: false
    t.boolean "can_modify_orders", default: false, null: false
    t.boolean "can_read", default: true, null: false
    t.boolean "can_view_analysis", default: false, null: false
    t.boolean "can_view_dashboard", default: false, null: false
    t.boolean "can_view_nomenclature", default: false, null: false
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

  add_foreign_key "order_lines", "orders"
  add_foreign_key "order_lines", "products"
  add_foreign_key "orders", "orders", column: "modifies_order_id", on_delete: :nullify
  add_foreign_key "orders", "suppliers"
  add_foreign_key "orders", "users"
  add_foreign_key "products", "suppliers"
  add_foreign_key "push_subscriptions", "users"
end
