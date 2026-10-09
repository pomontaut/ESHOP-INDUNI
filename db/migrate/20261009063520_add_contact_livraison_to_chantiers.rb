class AddContactLivraisonToChantiers < ActiveRecord::Migration[8.0]
  def up
    add_column :chantiers, :contact_livraison, :string
    add_column :chantiers, :natel_livraison, :string
    add_column :chantiers, :email_livraison, :string

    # Pedro Pinto est le contact de réception livraison pour ce chantier
    # (distinct du contremaître actuel, Cédric Gaillard) — ne cible que la
    # "Phase 2" précisément nommée, pas "12218-La Suettaz" (phase 1), qui a
    # son propre contremaître déjà nommé Pedro Pinto par coïncidence.
    Chantier.where("nom LIKE ?", "%La Suettaz%Phase 2%").update_all(
      contact_livraison: "PINTO Pedro",
      natel_livraison: "+41763656892",
      email_livraison: "ppinto@induni.ch"
    )
  end

  def down
    remove_column :chantiers, :contact_livraison
    remove_column :chantiers, :natel_livraison
    remove_column :chantiers, :email_livraison
  end
end
