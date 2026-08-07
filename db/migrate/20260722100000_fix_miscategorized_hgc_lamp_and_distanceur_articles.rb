class FixMiscategorizedHgcLampAndDistanceurArticles < ActiveRecord::Migration[8.1]
  # These HGC articles were tagged "Drainage & Canalisation / Tuyaux" purely
  # because their designation contains the word "tube" — a work light and a
  # batch of rebar/formwork spacer accessories, none of them actual pipes.
  # Sharing that family with real PVC/PE pipes fed bogus "équivalent probable"
  # matches into the storefront's cross-supplier comparison feature.
  RECLASSIFICATIONS = {
    "100021798" => { famille: "Équipement de Chantier", sous_famille: "Équipement",
                      icone: "🪣", image: "construction materials Équipement de Chantier" },
    "100012153" => :distanceur,
    "100013260" => :distanceur,
    "100013262" => :distanceur,
    "100013264" => :distanceur,
    "100013266" => :distanceur,
    "100013268" => :distanceur,
    "100013269" => :distanceur,
    "100013853" => :distanceur,
    "100073370" => :distanceur,
    "100073371" => :distanceur,
    "100073372" => :distanceur
  }.freeze

  DISTANCEUR_ATTRS = { famille: "Armatures & Distanceurs", sous_famille: "Distanceurs",
                        icone: "🏗️", image: "construction materials Armatures & Distanceurs" }.freeze

  def up
    hgc = Supplier.find_by(name: "HGC")
    return unless hgc

    RECLASSIFICATIONS.each do |reference, attrs|
      attrs = DISTANCEUR_ATTRS if attrs == :distanceur
      Product.where(supplier_id: hgc.id, reference: reference)
             .update_all(attrs.merge(sous_sous_famille: "__DIRECT__"))
    end
  end

  def down
    # Data fix only — no rollback of the previous (incorrect) categorization.
  end
end
