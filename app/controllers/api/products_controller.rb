class Api::ProductsController < ApplicationController
  skip_before_action :require_login

  def index
    products = Product.includes(:supplier).where.not(famille: nil).order(:id)
    render json: products.map { |p|
      {
        catalog:          p.supplier&.name,
        article:          p.reference,
        designation:      p.name,
        descriptif:       p.descriptif,
        prix:             p.unit_price.to_f,
        unite:            p.unite,
        famille:          p.famille,
        sousFamille:      p.sous_famille,
        sousSousFamille:  p.sous_sous_famille,
        icone:            p.icone,
        image:            p.image,
        equivalenceKey:   p.equivalence_key,
        qtePalette:       p.qte_palette
      }
    }
  end
end
