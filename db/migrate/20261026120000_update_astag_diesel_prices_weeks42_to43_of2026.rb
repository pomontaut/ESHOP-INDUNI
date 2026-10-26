class UpdateAstagDieselPricesWeeks42To43Of2026 < ActiveRecord::Migration[8.1]
  # Tableau hebdomadaire ASTAG/IRU 2026 mis à jour au 22.10.2026 : ajoute les
  # semaines 42 et 43 (lundis 12.10 et 19.10.2026), pas encore publiées lors de
  # la mise à jour précédente (qui couvrait jusqu'à la semaine 41).
  def up
    DieselPrice.upsert_all(
      [
        { week_start: "2026-10-12", price: 2.39, created_at: Time.current, updated_at: Time.current },
        { week_start: "2026-10-19", price: 2.41, created_at: Time.current, updated_at: Time.current }
      ],
      unique_by: :index_diesel_prices_on_week_start
    )
  end

  def down
    # Correction de données uniquement — pas de retour arrière possible.
  end
end
