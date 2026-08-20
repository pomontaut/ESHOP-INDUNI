class CreateCanplastSurcharges < ActiveRecord::Migration[8.1]
  def up
    create_table :canplast_surcharges do |t|
      t.string :codes, null: false
      t.string :label, null: false
      t.date :effective_date, null: false
      t.decimal :surcharge_pct, precision: 6, scale: 2, null: false
      t.string :source

      t.timestamps
    end
    add_index :canplast_surcharges, [ :codes, :effective_date ], unique: true

    # Historique repris de "synthese_hausses_prix_par_produit.xlsx" (comparaison
    # des avis de hausse Canplast successifs) — surcharge_pct = "nouvelle
    # hausse" en vigueur à la date d'effet, pour chaque groupe d'articles
    # (codes). Une baisse a eu lieu le 15.06.2026 (Baisses-15.06.26.pdf) mais
    # sa valeur n'a pas pu être quantifiée à partir des documents fournis —
    # voir la note affichée dans Indicateurs de marché.
    rows = [
      { codes: "A1, A2, A3", label: "tuyaux de canalisation et de drainage PVC compact", effective_date: "2026-03-27", surcharge_pct: 59.0, source: "Hausse-fin-mars-2026.pdf" },
      { codes: "B1-B5, C1-C6", label: "pièces en PVC", effective_date: "2026-03-27", surcharge_pct: 48.0, source: "Hausse-fin-mars-2026.pdf" },
      { codes: "D1, D3, D4, D8", label: "tuyaux de canalisation en PE", effective_date: "2026-03-27", surcharge_pct: 38.0, source: "Hausse-fin-mars-2026.pdf" },
      { codes: "D3PF", label: "tuyaux de drainage à fentes en PE série S10", effective_date: "2026-03-27", surcharge_pct: 15.0, source: "Hausse-fin-mars-2026.pdf" },
      { codes: "F5", label: "tuyaux de canalisation et drainage en PP", effective_date: "2026-03-27", surcharge_pct: 67.0, source: "Hausse-fin-mars-2026.pdf" },
      { codes: "F7", label: "tuyaux drainage en PP à fentes SN8 et SN16", effective_date: "2026-03-27", surcharge_pct: 56.0, source: "Hausse-fin-mars-2026.pdf" },
      { codes: "F6", label: "pièces en PP", effective_date: "2026-03-27", surcharge_pct: 33.0, source: "Hausse-fin-mars-2026.pdf" },
      { codes: "E1, E2, E3, J1-J4", label: "pièces câbles et canal en PE", effective_date: "2026-03-27", surcharge_pct: 10.0, source: "Hausse-fin-mars-2026.pdf" },
      { codes: "P2", label: "tubes pression PE100 en barre", effective_date: "2026-03-27", surcharge_pct: 26.0, source: "Hausse-fin-mars-2026.pdf" },
      { codes: "P1", label: "tubes pression PE100 en rouleaux", effective_date: "2026-03-27", surcharge_pct: 17.0, source: "Hausse-fin-mars-2026.pdf" },
      { codes: "A1, A2, A3", label: "tuyaux de canalisation et de drainage PVC compact", effective_date: "2026-04-08", surcharge_pct: 69.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "D1, D3, D4, D8", label: "tuyaux de canalisation en PE", effective_date: "2026-04-08", surcharge_pct: 50.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "D3PF", label: "tuyaux de drainage à fentes en PE série S10", effective_date: "2026-04-08", surcharge_pct: 25.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "F5", label: "tuyaux de canalisation et drainage en PP", effective_date: "2026-04-08", surcharge_pct: 80.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "F7", label: "tuyaux drainage en PP à fentes SN8 et SN16", effective_date: "2026-04-08", surcharge_pct: 77.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "D5-D7, D9, H6", label: "tuyaux en PE et en rouleau de 50 m", effective_date: "2026-04-08", surcharge_pct: 28.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "E1, E2, E3, J1-J4", label: "pièces câbles et canal en PE", effective_date: "2026-04-08", surcharge_pct: 10.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "P2", label: "tubes pression PE100 en barre", effective_date: "2026-04-08", surcharge_pct: 40.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "P1", label: "tubes pression PE100 en rouleaux", effective_date: "2026-04-08", surcharge_pct: 21.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "E4, P6", label: "manchons électrosoudables Plasson", effective_date: "2026-04-08", surcharge_pct: 24.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "C6..", label: "Raccord TCPVCF", effective_date: "2026-04-08", surcharge_pct: 12.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "C2..", label: "Raccord de piquage", effective_date: "2026-04-08", surcharge_pct: 8.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "C1.", label: "RCVGRIP", effective_date: "2026-04-08", surcharge_pct: 24.0, source: "Hausse-08.04.2026.pdf" },
      { codes: "H2, H5", label: "tubes de protection de câbles en PE-DUR recyclé", effective_date: "2026-04-27", surcharge_pct: 35.0, source: "Hausse_27.04.2026 (3).pdf" },
      { codes: "H1, H7", label: "tubes de protection de câbles en LD-PE", effective_date: "2026-04-27", surcharge_pct: 31.0, source: "Hausse_27.04.2026 (3).pdf" },
      { codes: "H4", label: "tubes de protection de câbles fermeture longitudinale", effective_date: "2026-04-27", surcharge_pct: 31.0, source: "Hausse_27.04.2026 (3).pdf" },
      { codes: "H7..", label: "tubes de protection de câbles en rouleaux K55-K40-K34-K28", effective_date: "2026-04-27", surcharge_pct: 58.0, source: "Hausse_27.04.2026 (3).pdf" },
      { codes: "A1, A2, A3", label: "tuyaux de canalisation et de drainage PVC compact", effective_date: "2026-05-01", surcharge_pct: 71.0, source: "Hausse-01.05.2026.pdf" },
      { codes: "D1, D3, D4, D8", label: "tuyaux de canalisation en PE", effective_date: "2026-05-01", surcharge_pct: 54.0, source: "Hausse-01.05.2026.pdf" },
      { codes: "D3PF", label: "tuyaux de drainage à fentes en PE série S10", effective_date: "2026-05-01", surcharge_pct: 29.0, source: "Hausse-01.05.2026.pdf" },
      { codes: "F5", label: "tuyaux de canalisation et drainage en PP", effective_date: "2026-05-01", surcharge_pct: 83.0, source: "Hausse-01.05.2026.pdf" },
      { codes: "F7", label: "tuyaux drainage en PP à fentes SN8 et SN16", effective_date: "2026-05-01", surcharge_pct: 81.0, source: "Hausse-01.05.2026.pdf" },
      { codes: "F6", label: "pièces en PP", effective_date: "2026-05-01", surcharge_pct: 37.0, source: "Hausse-01.05.2026.pdf" },
      { codes: "E1, E2, E3, J1-J4", label: "pièces câbles et canal en PE", effective_date: "2026-05-01", surcharge_pct: 12.0, source: "Hausse-01.05.2026.pdf" },
      { codes: "P2", label: "tubes pression PE100 en barre", effective_date: "2026-05-01", surcharge_pct: 47.0, source: "Hausse-01.05.2026.pdf" },
      { codes: "P1", label: "tubes pression PE100 en rouleaux", effective_date: "2026-05-01", surcharge_pct: 25.0, source: "Hausse-01.05.2026.pdf" }
    ]
    now = Time.current
    values = rows.map { |r|
      "(#{connection.quote(r[:codes])}, #{connection.quote(r[:label])}, #{connection.quote(r[:effective_date])}, #{r[:surcharge_pct]}, #{connection.quote(r[:source])}, #{connection.quote(now.to_fs(:db))}, #{connection.quote(now.to_fs(:db))})"
    }.join(",\n")
    execute("INSERT INTO canplast_surcharges (codes, label, effective_date, surcharge_pct, source, created_at, updated_at) VALUES\n#{values}")
  end

  def down
    drop_table :canplast_surcharges
  end
end
