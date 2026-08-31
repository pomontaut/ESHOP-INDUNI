class UpdateAstagDieselPricesWeek35Of2026 < ActiveRecord::Migration[8.1]
  # Tableau hebdomadaire ASTAG/IRU 2026 mis à jour au 31.08.2026 : ajoute la
  # semaine 35 (lundi 24.08.2026), pas encore publiée lors de la mise à jour
  # précédente (qui couvrait les semaines 1 à 34).
  def up
    DieselPrice.upsert_all(
      [ { week_start: "2026-08-24", price: 2.21, created_at: Time.current, updated_at: Time.current } ],
      unique_by: :index_diesel_prices_on_week_start
    )
  end

  def down
    # Correction de données uniquement — pas de retour arrière possible.
  end
end
