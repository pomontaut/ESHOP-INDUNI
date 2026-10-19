class AddFicheUrlToProducts < ActiveRecord::Migration[8.0]
  # Lien vers la fiche article sur le site du fournisseur (Swisspor, Sika, ALZO) ;
  # renseigné par le seed (catalog_products.json, clé « ficheUrl »).
  def change
    add_column :products, :fiche_url, :string
  end
end
