class ClassifyHiltiBurinsEtDisques < ActiveRecord::Migration[8.0]
  # Réorganisation demandée des sous-familles HILTI "Burins" (44 articles) et
  # "Disques" (67 articles), classées ici en sous-sous-familles lisibles dans
  # leur désignation :
  #
  # Burins (pas de sous-catégorie supplémentaire demandée) :
  #  - Burin plat / Burin à mortier / Burin pointu plat / Burin spatule
  #    déporté / Burin spatule / Goujon brique/béton / Kit burins, et
  #    "Burin pointu" (code SM/BP, sans "plat") en 8e catégorie : non demandé
  #    explicitement, mais un code produit HILTI distinct du "Burin pointu
  #    plat" (code FP) — le fondre dans l'un ou l'autre aurait été inexact.
  #
  # Disques (les séries SP/SPX, et P en complément, sont un niveau de détail
  # supplémentaire au sein de "Disque diamant"/"Kit disques" — géré côté
  # client par level4KindInduni, pas par une colonne) :
  #  - Disque à tronçonner (code AC-D, abrasif, pas de sous-catégorie)
  #  - Disque diamant (codes dia/mm, séries P/SP/SPX)
  #  - Kit disques (tout article "Kit ...", séries SP/SPX)
  MAPPING = {
    "Kit burins" => [ "2466617", "2466616", "2462842", "2462843", "2461749" ],
    "Burin spatule" => [ "2483296", "2207192", "2430331", "2429829", "2429845", "2429817", "2429803", "2429848", "2428759", "2429006" ],
    "Burin pointu plat" => [ "2466615", "2466805", "2466807", "2483283" ],
    "Burin pointu" => [ "2466800", "2452584", "2429828", "2430330", "2429847", "2429984", "2452918" ],
    "Burin plat" => [ "2429837", "2429826", "2429827", "2429838", "2453019" ],
    "Burin spatule déporté" => [ "2428754", "2428755", "2429750", "2428756", "2429805", "2429813" ],
    "Goujon brique/béton" => [ "2429005", "2429008", "2429816", "2429756" ],
    "Burin à mortier" => [ "2428757", "2429800", "2429757" ],
    "Disque à tronçonner" => [ "2181351", "2328062", "2181353", "2150736", "2181350", "2327758", "2181352", "2181354", "2150708", "2150735", "2150737" ],
    "Kit disques" => [ "2192079", "2468745", "2468746", "2468747", "2468748", "2468749", "2468750", "2468692", "2468693", "2468694", "2468695", "2468696", "2468697", "2468698", "2468699", "2468720", "2468721", "2468722", "2468723", "2468724", "2468725", "2468726", "2468736", "2468737", "2468738", "2468751", "2468752", "2468753", "2468754", "2468727", "2468728", "2468729", "2468730", "2468731", "2468732", "2468778", "2468779" ],
    "Disque diamant" => [ "2233555", "2345788", "2233561", "2346221", "2165458", "2117973", "2117977", "2233582", "2346224", "2233584", "2346227", "2165452", "2117897", "2117901", "2233572", "2346232", "2233575", "2346234", "2169813" ]
  }.freeze

  def up
    hilti = Supplier.find_by(name: "HILTI")
    return unless hilti

    MAPPING.each do |sous_sous_famille, references|
      Product.where(supplier: hilti, reference: references).update_all(sous_sous_famille: sous_sous_famille)
    end
  end

  def down
    # Non réversible proprement (regroupement par catégorie) : no-op délibéré.
  end
end
