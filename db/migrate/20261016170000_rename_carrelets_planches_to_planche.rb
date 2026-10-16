class RenameCarreletsPlanchesToPlanche < ActiveRecord::Migration[8.0]
  # « Carrelets / planches de coffrage » est scindé : « Planche de coffrage »
  # (27x…, 40x…) et « Carrelet » (80x…), rubriques « Planches de coffrage » et
  # « Carrelets » (HG COMMERCIALE et Leuba HIAG).
  # Idempotent ; les références d'article ne changent pas.
  OLD = "Carrelets / planches de coffrage".freeze

  def up
    # Sections 80x… : ce sont de vrais carrelets (rubrique « Carrelets »), les autres des planches.
    Product.where("name LIKE ?", "#{OLD} 80x%").find_each do |product|
      product.update_columns(name: product.name.sub(/\A#{Regexp.escape(OLD)}/, "Carrelet"), sous_famille: "Carrelets", updated_at: Time.current)
    end
    Product.where(sous_famille: OLD).update_all(sous_famille: "Planches de coffrage", updated_at: Time.current)
    Product.where("name LIKE ?", "#{OLD}%").find_each do |product|
      product.update_columns(name: product.name.sub(/\A#{Regexp.escape(OLD)}/, "Planche de coffrage"), updated_at: Time.current)
    end
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
