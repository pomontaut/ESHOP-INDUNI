class UpdateAstagDieselPricesWeek38Of2026 < ActiveRecord::Migration[8.1]
  # Tableau hebdomadaire ASTAG/IRU 2026 mis à jour au 17.09.2026 : ajoute la
  # semaine 38 (lundi 14.09.2026), pas encore publiée lors de la mise à jour
  # précédente (qui couvrait jusqu'à la semaine 37).
  def up
    DieselPrice.upsert_all(
      [ { week_start: "2026-09-14", price: 2.32, created_at: Time.current, updated_at: Time.current } ],
      unique_by: :index_diesel_prices_on_week_start
    )
  end

  def down
    # Correction de données uniquement — pas de retour arrière possible.
  end
end
