class RenameBoisC24ToPlateauBoisC24 < ActiveRecord::Migration[8.0]
  # « Bois C24 » devient « Plateau bois C24 » (rubrique et désignations) pour
  # HG COMMERCIALE et Leuba HIAG. Idempotent : ne touche que ce qui porte encore
  # l'ancien libellé. La référence (n° d'article) ne change pas, donc les
  # commandes passées et les équivalences restent rattachées au même article.
  FAMILLE = "Bois & Coffrage".freeze

  def up
    Product.where(famille: FAMILLE, sous_famille: "Bois C24").find_each do |product|
      product.update_columns(
        sous_famille: "Plateau bois C24",
        name: product.name.to_s.sub(/\ABois C24/, "Plateau bois C24"),
        updated_at: Time.current
      )
    end
    # Articles ajoutés hors de la rubrique mais portant l'ancien libellé.
    Product.where(famille: FAMILLE).where("name LIKE ?", "Bois C24%").find_each do |product|
      product.update_columns(name: product.name.sub(/\ABois C24/, "Plateau bois C24"), updated_at: Time.current)
    end
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
