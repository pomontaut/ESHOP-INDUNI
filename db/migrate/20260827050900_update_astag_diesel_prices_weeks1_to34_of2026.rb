class UpdateAstagDieselPricesWeeks1To34Of2026 < ActiveRecord::Migration[8.1]
  # Tableau hebdomadaire ASTAG/IRU 2026 (CHF/litre, TVA incl.), semaines 1 à
  # 34 (jusqu'au 17.08.2026 — la semaine 35 et suivantes n'étaient pas
  # encore publiées au moment de cette mise à jour). Chaque "Woche" ISO de
  # 2026 commence le lundi ; la semaine 1 démarre le 29.12.2025 (l'année
  # 2026 commence un jeudi). Upsert par week_start pour créer les semaines
  # manquantes et corriger celles déjà saisies si besoin.
  WEEKLY_PRICES = {
    "2025-12-29" => 1.77, "2026-01-05" => 1.77, "2026-01-12" => 1.77, "2026-01-19" => 1.76,
    "2026-01-26" => 1.75, "2026-02-02" => 1.74, "2026-02-09" => 1.74, "2026-02-16" => 1.75,
    "2026-02-23" => 1.74, "2026-03-02" => 1.74, "2026-03-09" => 1.82, "2026-03-16" => 1.90,
    "2026-03-23" => 2.03, "2026-03-30" => 2.09, "2026-04-06" => 2.15, "2026-04-13" => 2.11,
    "2026-04-20" => 2.10, "2026-04-27" => 2.11, "2026-05-04" => 2.12, "2026-05-11" => 2.12,
    "2026-05-18" => 2.11, "2026-05-25" => 2.11, "2026-06-01" => 2.10, "2026-06-08" => 2.09,
    "2026-06-15" => 2.07, "2026-06-22" => 2.03, "2026-06-29" => 2.00, "2026-07-06" => 1.99,
    "2026-07-13" => 2.02, "2026-07-20" => 2.06, "2026-07-27" => 2.12, "2026-08-03" => 2.14,
    "2026-08-10" => 2.15, "2026-08-17" => 2.19
  }.freeze

  def up
    now = Time.current
    rows = WEEKLY_PRICES.map { |week_start, price| { week_start: week_start, price: price, created_at: now, updated_at: now } }
    DieselPrice.upsert_all(rows, unique_by: :index_diesel_prices_on_week_start)
  end

  def down
    # Correction de données uniquement — pas de retour arrière possible.
  end
end
