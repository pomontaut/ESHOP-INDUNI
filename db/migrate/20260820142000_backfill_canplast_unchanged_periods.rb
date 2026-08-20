class BackfillCanplastUnchangedPeriods < ActiveRecord::Migration[8.1]
  # La table ne contenait jusqu'ici que les dates où un groupe d'articles a
  # effectivement reçu un nouvel avis de hausse. Pour afficher l'historique
  # complet (y compris les dates où le taux n'a pas changé pour ce groupe),
  # on reporte la dernière valeur connue sur les dates suivantes où aucun
  # nouvel avis n'existait pour ce groupe — d'après "Vue produit-date" dans
  # synthese_hausses_prix_par_produit.xlsx.
  def up
    tracked_dates = %w[2026-03-27 2026-04-08 2026-04-27 2026-05-01]

    unchanged = [
      { codes: "A1, A2, A3", label: "tuyaux de canalisation et de drainage PVC compact", effective_date: "2026-04-27", surcharge_pct: 69.0 },
      { codes: "B1-B5, C1-C6", label: "pièces en PVC", effective_date: "2026-04-08", surcharge_pct: 48.0 },
      { codes: "B1-B5, C1-C6", label: "pièces en PVC", effective_date: "2026-04-27", surcharge_pct: 48.0 },
      { codes: "B1-B5, C1-C6", label: "pièces en PVC", effective_date: "2026-05-01", surcharge_pct: 48.0 },
      { codes: "D1, D3, D4, D8", label: "tuyaux de canalisation en PE", effective_date: "2026-04-27", surcharge_pct: 50.0 },
      { codes: "D3PF", label: "tuyaux de drainage à fentes en PE série S10", effective_date: "2026-04-27", surcharge_pct: 25.0 },
      { codes: "F5", label: "tuyaux de canalisation et drainage en PP", effective_date: "2026-04-27", surcharge_pct: 80.0 },
      { codes: "F7", label: "tuyaux drainage en PP à fentes SN8 et SN16", effective_date: "2026-04-27", surcharge_pct: 77.0 },
      { codes: "F6", label: "pièces en PP", effective_date: "2026-04-08", surcharge_pct: 33.0 },
      { codes: "F6", label: "pièces en PP", effective_date: "2026-04-27", surcharge_pct: 33.0 },
      { codes: "E1, E2, E3, J1-J4", label: "pièces câbles et canal en PE", effective_date: "2026-04-27", surcharge_pct: 10.0 },
      { codes: "P2", label: "tubes pression PE100 en barre", effective_date: "2026-04-27", surcharge_pct: 40.0 },
      { codes: "P1", label: "tubes pression PE100 en rouleaux", effective_date: "2026-04-27", surcharge_pct: 21.0 },
      { codes: "D5-D7, D9, H6", label: "tuyaux en PE et en rouleau de 50 m", effective_date: "2026-04-27", surcharge_pct: 28.0 },
      { codes: "D5-D7, D9, H6", label: "tuyaux en PE et en rouleau de 50 m", effective_date: "2026-05-01", surcharge_pct: 28.0 },
      { codes: "E4, P6", label: "manchons électrosoudables Plasson", effective_date: "2026-04-27", surcharge_pct: 24.0 },
      { codes: "E4, P6", label: "manchons électrosoudables Plasson", effective_date: "2026-05-01", surcharge_pct: 24.0 },
      { codes: "C6..", label: "Raccord TCPVCF", effective_date: "2026-04-27", surcharge_pct: 12.0 },
      { codes: "C6..", label: "Raccord TCPVCF", effective_date: "2026-05-01", surcharge_pct: 12.0 },
      { codes: "C2..", label: "Raccord de piquage", effective_date: "2026-04-27", surcharge_pct: 8.0 },
      { codes: "C2..", label: "Raccord de piquage", effective_date: "2026-05-01", surcharge_pct: 8.0 },
      { codes: "C1.", label: "RCVGRIP", effective_date: "2026-04-27", surcharge_pct: 24.0 },
      { codes: "C1.", label: "RCVGRIP", effective_date: "2026-05-01", surcharge_pct: 24.0 },
      { codes: "H2, H5", label: "tubes de protection de câbles en PE-DUR recyclé", effective_date: "2026-05-01", surcharge_pct: 35.0 },
      { codes: "H1, H7", label: "tubes de protection de câbles en LD-PE", effective_date: "2026-05-01", surcharge_pct: 31.0 },
      { codes: "H4", label: "tubes de protection de câbles fermeture longitudinale", effective_date: "2026-05-01", surcharge_pct: 31.0 },
      { codes: "H7..", label: "tubes de protection de câbles en rouleaux K55-K40-K34-K28", effective_date: "2026-05-01", surcharge_pct: 58.0 }
    ]

    now = Time.current
    values = unchanged.map { |r|
      "(#{connection.quote(r[:codes])}, #{connection.quote(r[:label])}, #{connection.quote(r[:effective_date])}, #{r[:surcharge_pct]}, #{connection.quote('(valeur inchangée)')}, #{connection.quote(now.to_fs(:db))}, #{connection.quote(now.to_fs(:db))})"
    }.join(",\n")
    execute("INSERT INTO canplast_surcharges (codes, label, effective_date, surcharge_pct, source, created_at, updated_at) VALUES\n#{values}\nON CONFLICT (codes, effective_date) DO NOTHING")
  end

  def down
    execute("DELETE FROM canplast_surcharges WHERE source = '(valeur inchangée)'")
  end
end
