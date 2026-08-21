class AddCanplast15Juin2026Update < ActiveRecord::Migration[8.1]
  # Reprend le document "Baisses-15.06.26.pdf" enfin fourni : la date de
  # baisse manquante depuis le 01.05.2026 pour les 19 groupes déjà suivis,
  # plus 3 nouveaux groupes numériques révélés par ce document (les groupes
  # "Sur demande" et la page 2 — chambres, cuves, caniveaux, etc. — ne sont
  # pas ajoutés : ce sont des familles jamais suivies jusqu'ici, en dehors
  # de la demande initiale).
  def up
    rows = [
      { codes: "A1, A2, A3", label: "tuyaux de canalisation et de drainage PVC compact", surcharge_pct: 68.0 },
      { codes: "B1-B5, C1-C6", label: "pièces en PVC", surcharge_pct: 48.0 },
      { codes: "D1, D3, D4, D8", label: "tuyaux de canalisation en PE", surcharge_pct: 54.0 },
      { codes: "D3PF", label: "tuyaux de drainage à fentes en PE série S10", surcharge_pct: 29.0 },
      { codes: "F5", label: "tuyaux de canalisation et drainage en PP", surcharge_pct: 78.0 },
      { codes: "F7", label: "tuyaux drainage en PP à fentes SN8 et SN16", surcharge_pct: 80.0 },
      { codes: "F6", label: "pièces en PP", surcharge_pct: 37.0 },
      { codes: "D5-D7, D9, H6", label: "tuyaux en PE et en rouleau de 50 m", surcharge_pct: 28.0 },
      { codes: "H2, H5", label: "tubes de protection de câbles en PE-DUR recyclé", surcharge_pct: 35.0 },
      { codes: "H1, H7", label: "tubes de protection de câbles en LD-PE", surcharge_pct: 31.0 },
      { codes: "H4", label: "tubes de protection de câbles fermeture longitudinale", surcharge_pct: 31.0 },
      { codes: "H7..", label: "tubes de protection de câbles en rouleaux K55-K40-K34-K28", surcharge_pct: 58.0 },
      { codes: "E1, E2, E3, J1-J4", label: "pièces câbles et canal en PE", surcharge_pct: 12.0 },
      { codes: "P2", label: "tubes pression PE100 en barre", surcharge_pct: 42.0 },
      { codes: "P1", label: "tubes pression PE100 en rouleaux", surcharge_pct: 22.0 },
      { codes: "E4, P6", label: "manchons électrosoudables Plasson", surcharge_pct: 24.0 },
      { codes: "C6..", label: "Raccord TCPVCF", surcharge_pct: 12.0 },
      { codes: "C2..", label: "Raccord de piquage", surcharge_pct: 8.0 },
      { codes: "C1.", label: "RCVGRIP", surcharge_pct: 24.0 },
      # Nouveaux groupes révélés par ce document, jamais suivis auparavant.
      { codes: "C4.", label: "pièces en PVC — coudes plongeur et bouchons lisses <250mm", surcharge_pct: 50.0 },
      { codes: "D3P", label: "tuyaux de drainage perforés en PE-DUR recyclé", surcharge_pct: 26.0 },
      { codes: "H3", label: "tubes de protection de câbles en HD-PE 1ère qualité (Gliss)", surcharge_pct: 38.0 },
      { codes: "VPC", label: "Raccord VPC", surcharge_pct: 5.0 }
    ]

    now = Time.current
    values = rows.map { |r|
      "(#{connection.quote(r[:codes])}, #{connection.quote(r[:label])}, '2026-06-15', #{r[:surcharge_pct]}, #{connection.quote('Baisses-15.06.26.pdf')}, #{connection.quote(now.to_fs(:db))}, #{connection.quote(now.to_fs(:db))})"
    }.join(",\n")
    execute("INSERT INTO canplast_surcharges (codes, label, effective_date, surcharge_pct, source, created_at, updated_at) VALUES\n#{values}\nON CONFLICT (codes, effective_date) DO NOTHING")
  end

  def down
    execute("DELETE FROM canplast_surcharges WHERE effective_date = '2026-06-15'")
  end
end
