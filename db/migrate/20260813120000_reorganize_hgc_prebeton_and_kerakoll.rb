class ReorganizeHgcPrebetonAndKerakoll < ActiveRecord::Migration[8.1]
  # Catalog reorganization requested by the client:
  #   - 2 Kerakoll cement bags move from "Ciments en sac" /
  #     "Autres produits ciments-bétons-mortiers" into the existing
  #     "Bétons & Mortiers" / "Sacs 25 kg" sous-sous-famille.
  #   - 5 "saut-de-loup" grille/caillebotis articles move out of the
  #     "Ciments & Bétons" famille into a brand-new "Pré-béton" famille
  #     with a "Saut de loup" sous-famille (kept distinct from the
  #     existing, unrelated "Préfa-béton" famille).
  #
  # Only touches these 7 rows directly by reference (see
  # AddHgcCaniveauAndCimentArticlePhotos for why a full-catalog loop is
  # too slow against Railway's networked Postgres).
  KERAKOLL_REFERENCES = %w[100022812 100084516].freeze
  SAUT_DE_LOUP_REFERENCES = %w[100081556 100078195 100078200 100078193 100078194].freeze

  def up
    supplier = Supplier.find_by(name: "HGC")
    return unless supplier

    Product.where(supplier_id: supplier.id, reference: KERAKOLL_REFERENCES).update_all(
      sous_famille: "Bétons & Mortiers",
      sous_sous_famille: "Sacs 25 kg"
    )

    Product.where(supplier_id: supplier.id, reference: SAUT_DE_LOUP_REFERENCES).update_all(
      famille: "Pré-béton",
      sous_famille: "Saut de loup",
      icone: "🕳️"
    )
  end

  def down
    # Data fix only — no rollback.
  end
end
