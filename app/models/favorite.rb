# Article favori d'un utilisateur, rangé par fournisseur (catalog). La clé
# (catalog, article, designation) est la même que celle du panier côté SPA,
# donc elle survit à un re-seed du catalogue (pas de product_id).
class Favorite < ApplicationRecord
  belongs_to :user

  validates :catalog, :article, presence: true
  validates :article, uniqueness: { scope: [ :user_id, :catalog, :designation ] }

  def as_json(*)
    { catalog: catalog, article: article, designation: designation }
  end
end
