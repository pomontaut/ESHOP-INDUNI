class CreateEshopMetrics < ActiveRecord::Migration[8.0]
  # Indicateurs de construction de l'e-shop, un relevé par jour (voir EshopMetric). L'historique depuis
  # le 1er octobre est reconstitué depuis git (script/build_eshop_metrics_history.py →
  # db/seed_data/eshop_metrics_history.json) ; les jours suivants sont mesurés en direct.
  def up
    create_table :eshop_metrics do |t|
      t.date    :metric_date, null: false
      t.integer :references_count, null: false, default: 0
      t.integer :equivalent_count, null: false, default: 0
      t.integer :induni_count, null: false, default: 0
      t.integer :catalogs_count, null: false, default: 0
      t.integer :photos_count, null: false, default: 0
      t.string  :source, null: false, default: "live"
      t.timestamps
    end
    add_index :eshop_metrics, :metric_date, unique: true
    EshopMetric.reset_column_information
    EshopMetric.seed_history!
  end

  def down
    drop_table :eshop_metrics
  end
end
