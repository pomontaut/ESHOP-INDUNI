class UpdateAstagDieselPricesWeeks39To41Of2026 < ActiveRecord::Migration[8.1]
  # Tableau hebdomadaire ASTAG/IRU 2026 mis à jour au 08.10.2026 : ajoute les
  # semaines 39 à 41 (lundis 21.09, 28.09 et 05.10.2026), pas encore publiées
  # lors de la mise à jour précédente (qui couvrait jusqu'à la semaine 38).
  def up
    DieselPrice.upsert_all(
      [
        { week_start: "2026-09-21", price: 2.39, created_at: Time.current, updated_at: Time.current },
        { week_start: "2026-09-28", price: 2.40, created_at: Time.current, updated_at: Time.current },
        { week_start: "2026-10-05", price: 2.39, created_at: Time.current, updated_at: Time.current }
      ],
      unique_by: :index_diesel_prices_on_week_start
    )
  end

  def down
    # Correction de données uniquement — pas de retour arrière possible.
  end
end
