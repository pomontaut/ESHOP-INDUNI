class AddPhotosToEfcoProducts < ActiveRecord::Migration[8.0]
  # Photos transmises par le fournisseur EFCO (fichier EFCO.xlsx) : 12 photos
  # représentatives, chacune partagée par toutes les références d'un même
  # modèle/catégorie (comme pour les autres catalogues).
  IMAGE_BY_REFERENCE = {
    "C50954" => "/images/products/efco-accessoires-resine.png",

    "D07290" => "/images/products/efco-batterie-bosch.png",
    "D07408" => "/images/products/efco-batterie-bosch.png",
    "D08159" => "/images/products/efco-batterie-bosch.png",

    "D07216" => "/images/products/efco-accessoires-aspirateur.png",
    "D07232" => "/images/products/efco-accessoires-aspirateur.png",
    "D07234" => "/images/products/efco-accessoires-aspirateur.png",
    "D07424" => "/images/products/efco-accessoires-aspirateur.png",

    "A64140" => "/images/products/efco-boulon.png",
    "A64165" => "/images/products/efco-boulon.png",
    "A64166" => "/images/products/efco-boulon.png",
    "A64170" => "/images/products/efco-boulon.png",

    "D17420" => "/images/products/efco-burinage.png",
    "D17421" => "/images/products/efco-burinage.png",
    "D17422" => "/images/products/efco-burinage.png",
    "D17423" => "/images/products/efco-burinage.png",
    "D17424" => "/images/products/efco-burinage.png",
    "D17425" => "/images/products/efco-burinage.png",
    "D17426" => "/images/products/efco-burinage.png",
    "D17427" => "/images/products/efco-burinage.png",
    "D17667" => "/images/products/efco-burinage.png",
    "D17801" => "/images/products/efco-burinage.png",
    "D17803" => "/images/products/efco-burinage.png",
    "D17806" => "/images/products/efco-burinage.png",
    "D17820" => "/images/products/efco-burinage.png",
    "D17821" => "/images/products/efco-burinage.png",
    "D17826" => "/images/products/efco-burinage.png",
    "D17827" => "/images/products/efco-burinage.png",
    "D17828" => "/images/products/efco-burinage.png",
    "D17829" => "/images/products/efco-burinage.png",
    "D18100" => "/images/products/efco-burinage.png",
    "D18110" => "/images/products/efco-burinage.png",

    "A44512" => "/images/products/efco-clou-spike.png",
    "A44513" => "/images/products/efco-clou-spike.png",
    "A44514" => "/images/products/efco-clou-spike.png",
    "A44515" => "/images/products/efco-clou-spike.png",
    "A44810" => "/images/products/efco-clou-spike.png",
    "A44811" => "/images/products/efco-clou-spike.png",

    "B38104" => "/images/products/efco-clou-spit.png",
    "B38106" => "/images/products/efco-clou-spit.png",
    "B38112" => "/images/products/efco-clou-spit.png",
    "B38113" => "/images/products/efco-clou-spit.png",
    "B38115" => "/images/products/efco-clou-spit.png",
    "B38162" => "/images/products/efco-clou-spit.png",
    "B38320" => "/images/products/efco-clou-spit.png",
    "B38321" => "/images/products/efco-clou-spit.png",

    "D21363" => "/images/products/efco-metabo-bp10.png",
    "D21359" => "/images/products/efco-metabo-dls-rilsan.png",
    "D20850" => "/images/products/efco-metabo-power-180-5.png",
    "D20450" => "/images/products/efco-metabo-power-280-20.png",
    "D21365" => "/images/products/efco-metabo-rf60g.png"
  }.freeze

  def up
    efco = Supplier.find_by(name: "EFCO")
    return unless efco

    IMAGE_BY_REFERENCE.each do |reference, image_path|
      Product.where(supplier: efco, reference: reference).update_all(image: image_path)
    end
  end

  def down
    efco = Supplier.find_by(name: "EFCO")
    return unless efco

    Product.where(supplier: efco, reference: IMAGE_BY_REFERENCE.keys).update_all(image: nil)
  end
end
