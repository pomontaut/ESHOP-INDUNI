class CreateDieselPrices < ActiveRecord::Migration[8.1]
  def up
    create_table :diesel_prices do |t|
      t.date :week_start, null: false
      t.decimal :price, precision: 6, scale: 3, null: false

      t.timestamps
    end
    add_index :diesel_prices, :week_start, unique: true

    # Historique 2026 repris du tableau ASTAG "Tableau des carburants pour
    # les transports nationaux" (source IRU, prix CHF/litre TVA incl.) —
    # base 0% = CHF 1.64/litre. Les semaines suivantes sont ajoutées via
    # /admin (voir Admin::DieselPricesController), pas par migration.
    historical = [
      { week_start: "2025-12-29", price: 1.77 },
      { week_start: "2026-01-05", price: 1.77 },
      { week_start: "2026-01-12", price: 1.77 },
      { week_start: "2026-01-19", price: 1.76 },
      { week_start: "2026-01-26", price: 1.75 },
      { week_start: "2026-02-02", price: 1.74 },
      { week_start: "2026-02-09", price: 1.74 },
      { week_start: "2026-02-16", price: 1.75 },
      { week_start: "2026-02-23", price: 1.74 },
      { week_start: "2026-03-02", price: 1.74 },
      { week_start: "2026-03-09", price: 1.82 },
      { week_start: "2026-03-16", price: 1.90 },
      { week_start: "2026-03-23", price: 2.03 },
      { week_start: "2026-03-30", price: 2.09 },
      { week_start: "2026-04-06", price: 2.15 },
      { week_start: "2026-04-13", price: 2.11 },
      { week_start: "2026-04-20", price: 2.10 },
      { week_start: "2026-04-27", price: 2.11 },
      { week_start: "2026-05-04", price: 2.12 },
      { week_start: "2026-05-11", price: 2.12 },
      { week_start: "2026-05-18", price: 2.11 },
      { week_start: "2026-05-25", price: 2.11 },
      { week_start: "2026-06-01", price: 2.10 },
      { week_start: "2026-06-08", price: 2.09 },
      { week_start: "2026-06-15", price: 2.07 },
      { week_start: "2026-06-22", price: 2.03 },
      { week_start: "2026-06-29", price: 2.00 },
      { week_start: "2026-07-06", price: 1.99 },
      { week_start: "2026-07-13", price: 2.02 },
      { week_start: "2026-07-20", price: 2.06 },
      { week_start: "2026-07-27", price: 2.12 },
      { week_start: "2026-08-03", price: 2.14 },
      { week_start: "2026-08-10", price: 2.15 },
      { week_start: "2026-08-17", price: 2.19 }
    ]
    now = Time.current
    rows = historical.map { |h| h.merge(created_at: now, updated_at: now) }
    execute(<<~SQL) if rows.any?
      INSERT INTO diesel_prices (week_start, price, created_at, updated_at) VALUES
      #{rows.map { |r| "('#{r[:week_start]}', #{r[:price]}, '#{now.to_fs(:db)}', '#{now.to_fs(:db)}')" }.join(",\n")}
    SQL
  end

  def down
    drop_table :diesel_prices
  end
end
