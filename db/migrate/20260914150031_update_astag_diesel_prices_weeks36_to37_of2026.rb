class UpdateAstagDieselPricesWeeks36To37Of2026 < ActiveRecord::Migration[8.1]
  # Tableau hebdomadaire ASTAG/IRU 2026 mis à jour au 10.09.2026 : ajoute les
  # semaines 36 (lundi 31.08.2026) et 37 (lundi 07.09.2026), pas encore
  # publiées lors de la mise à jour précédente (qui couvrait jusqu'à la
  # semaine 35).
  def up
    DieselPrice.upsert_all(
      [
        { week_start: "2026-08-31", price: 2.21, created_at: Time.current, updated_at: Time.current },
        { week_start: "2026-09-07", price: 2.24, created_at: Time.current, updated_at: Time.current }
      ],
      unique_by: :index_diesel_prices_on_week_start
    )
  end

  def down
    # Correction de données uniquement — pas de retour arrière possible.
  end
end
