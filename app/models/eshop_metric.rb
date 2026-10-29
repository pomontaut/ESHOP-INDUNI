# Indicateurs de construction de l'e-shop, un relevé par jour (écran Admin > Indicateurs).
# Définitions (identiques à script/build_eshop_metrics_history.py) :
# - references : articles avec une famille (les articles sortis du catalogue n'en ont plus) ;
# - equivalent : articles dont la clé d'équivalence est partagée par au moins 2 catalogues fournisseurs ;
# - induni     : articles ayant une ligne de nomenclature INDUNI (n° + désignation) ;
# - catalogs   : catalogues fournisseurs distincts ayant des articles ;
# - photos     : articles avec une photo.
class EshopMetric < ApplicationRecord
  HISTORY_PATH = Rails.root.join("db/seed_data/eshop_metrics_history.json")
  START_DATE = Date.new(2026, 10, 1)

  validates :metric_date, presence: true, uniqueness: true

  # Mesure en direct depuis la base.
  def self.compute_live
    prods = Product.joins(:supplier).where.not(famille: [ nil, "" ])
    keys = prods.where.not(equivalence_key: [ nil, "" ]).group(:equivalence_key).having("COUNT(DISTINCT products.supplier_id) >= 2").pluck(:equivalence_key)
    induni = NomenclatureEntry.where.not(induni_designation: [ nil, "" ]).pluck(:supplier_name, :supplier_reference).to_set
    catalog = prods.pluck("suppliers.name", "products.reference")
    {
      references_count: prods.count,
      equivalent_count: keys.empty? ? 0 : prods.where(equivalence_key: keys).count,
      induni_count:     catalog.count { |k| induni.include?(k) },
      catalogs_count:   prods.distinct.count(:supplier_id),
      photos_count:     prods.where.not(image: [ nil, "" ]).count
    }
  end

  # Relevé du jour (mis à jour tout au long de la journée : la dernière valeur du jour fait foi).
  def self.snapshot!(date = UsageReport::ZONE.today)
    row = find_or_initialize_by(metric_date: date)
    return row if row.persisted? && row.source == "git" && date < UsageReport::ZONE.today

    row.assign_attributes(compute_live.merge(source: "live"))
    row.save!
    row
  end

  # Historique reconstitué depuis git : n'écrase jamais un relevé existant.
  def self.seed_history!(path = HISTORY_PATH)
    return 0 unless File.exist?(path)

    n = 0
    JSON.parse(File.read(path)).each do |r|
      next if exists?(metric_date: r["date"])

      create!(metric_date: r["date"], references_count: r["references"], equivalent_count: r["equivalent"],
              induni_count: r["induni"], catalogs_count: r["catalogs"], photos_count: r["photos"], source: r["source"] || "git")
      n += 1
    end
    n
  end

  def self.series(from = START_DATE)
    snapshot!
    where("metric_date >= ?", from).order(:metric_date).map do |m|
      refs = m.references_count
      pct = ->(n) { refs.zero? ? 0 : (100.0 * n / refs).round(1) }
      { date: m.metric_date.iso8601, references: refs, equivalent: m.equivalent_count, equivalent_pct: pct.(m.equivalent_count),
        induni: m.induni_count, induni_pct: pct.(m.induni_count), catalogs: m.catalogs_count,
        photos: m.photos_count, photos_pct: pct.(m.photos_count), source: m.source }
    end
  end
end
