class AddHgcSautDeLoupCuisse < ActiveRecord::Migration[8.1]
  # HGC « Préfa-béton › Saut de loup » : 63 sauts-de-loup à cuisse 60/70/80 cm (hgc.ch, prix nets).
  REFERENCES = %w[
    100119525 100119526 100119527 100119528 100119529 100119830 100119831 100119832 100119833
    100119834 100119835 100119836 100119837 100119838 100119839 100119840 100119841 100119842
    100119843 100119844 100119845 100119846 100119847 100119848 100119849 100119850 100119851
    100119852 100119853 100119854 100119855 100119856 100119857 100119858 100119859 100119860
    100119861 100119862 100119863 100119864 100119865 100119866 100119867 100119868 100119869
    100119870 100119871 100119872 100119873 100119874 100119875 100119876 100119877 100119878
    100119879 100119880 100119881 100119882 100119883 100119884 100119885 100119886 100119887
  ].freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    path = Rails.root.join("db/seed_data/catalog_products.json")
    return unless File.exist?(path)

    items = JSON.parse(File.read(path)).select do |it|
      it["catalog"] == "HG COMMERCIALE" && REFERENCES.include?(it["article"])
    end
    now = Time.current

    rows = items.map do |it|
      {
        supplier_id:       hgc.id,
        reference:         it["article"],
        name:              it["designation"],
        unit_price:        it["prix"],
        descriptif:        it["descriptif"],
        unite:             it["unite"],
        famille:           it["famille"],
        sous_famille:      it["sousFamille"],
        sous_sous_famille: it["sousSousFamille"],
        icone:             it["icone"],
        poids_kg:          it["poids"],
        image:             it["image"],
        created_at:        now,
        updated_at:        now
      }
    end

    Product.upsert_all(rows, unique_by: :index_products_on_supplier_id_and_reference) if rows.any?
  end

  def down
    # Data refresh only — no rollback of catalog contents.
  end
end
