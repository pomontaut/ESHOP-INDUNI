class LinkHgcCanplastProtectionCablesEquivalences2 < ActiveRecord::Migration[8.1]
  # Équivalences HGC ↔ Canplast « Protection Câbles » validées par le propriétaire
  # (suite : manchons fendus / réparation, réductions, bouchons, DIL-FORCE, tubes durs recyclés,
  # tubes à fermeture longitudinale, K-série). Clé = n° d'article HGC du groupe, posée sur tous
  # les articles du groupe. Un article Canplast lié à plusieurs articles HGC (ex. CLPETF092 :
  # L5 m et L10 m) forme UN groupe : un seul equivalence_key par produit.
  GROUPS = {
    "100075287" => { hgc: ["100075287"], canplast: ["CLPEMF092"] },
    "100075288" => { hgc: ["100075288", "100053980"], canplast: ["CLPEMF112"] },
    "100075289" => { hgc: ["100075289"], canplast: ["CLPEMF132"] },
    "100075290" => { hgc: ["100075290"], canplast: ["CLPEMF163"] },
    "100033975" => { hgc: ["100033975"], canplast: ["CLPEMF214"] },
    "100053989" => { hgc: ["100053989"], canplast: ["CLPEMR132"] },
    "100056194" => { hgc: ["100056194"], canplast: ["CLPERED092072"] },
    "100075093" => { hgc: ["100075093"], canplast: ["CLPERED112092"] },
    "100077862" => { hgc: ["100077862"], canplast: ["CLPERED132112"] },
    "100077863" => { hgc: ["100077863"], canplast: ["CLPERED163132"] },
    "100081818" => { hgc: ["100081818"], canplast: ["CLPERED112072"] },
    "100081819" => { hgc: ["100081819"], canplast: ["CLPERED132092"] },
    "100081820" => { hgc: ["100081820"], canplast: ["CLPERED163112"] },
    "100032607" => { hgc: ["100032607"], canplast: ["CLPEBM072"] },
    "100032609" => { hgc: ["100032609"], canplast: ["CLPEBM092"] },
    "100032651" => { hgc: ["100032651"], canplast: ["CLPEBM112"] },
    "100032653" => { hgc: ["100032653"], canplast: ["CLPEBM132"] },
    "100033273" => { hgc: ["100033273"], canplast: ["CLPED11210"] },
    "100033275" => { hgc: ["100033275"], canplast: ["CLPED13210"] },
    "100033277" => { hgc: ["100033277"], canplast: ["CLPED16310"] },
    "100033279" => { hgc: ["100033279"], canplast: ["CLPED21410"] },
    "100075095" => { hgc: ["100075095", "100033024"], canplast: ["CLPEDR07210"] },
    "100075097" => { hgc: ["100075097", "100033028"], canplast: ["CLPEDR09210"] },
    "100075099" => { hgc: ["100075099", "100033062"], canplast: ["CLPEDR11210"] },
    "100075101" => { hgc: ["100075101", "100033066"], canplast: ["CLPEDR13210"] },
    "100075103" => { hgc: ["100075103", "100033110"], canplast: ["CLPEDR16310"] },
    "100075283" => { hgc: ["100075283", "100033841"], canplast: ["CLPETF092"] },
    "100075284" => { hgc: ["100075284", "100033845"], canplast: ["CLPETF112"] },
    "100075285" => { hgc: ["100075285", "100091983"], canplast: ["CLPETF132"] },
    "100053929" => { hgc: ["100053929"], canplast: ["CLPEK100D"] },
    "100053923" => { hgc: ["100053923"], canplast: ["CLPEK100"] },
    "100053921" => { hgc: ["100053921"], canplast: ["CLPEK55"] },
    "100053899" => { hgc: ["100053899"], canplast: ["CLPEK555"] }
  }.freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    canplast = Supplier.find_by(name: "Canplast")
    return unless hgc && canplast

    GROUPS.each do |key, refs|
      Product.where(supplier_id: hgc.id, reference: refs[:hgc]).update_all(equivalence_key: key)
      Product.where(supplier_id: canplast.id, reference: refs[:canplast]).update_all(equivalence_key: key)
    end
  end

  def down
    # Data refresh only — no rollback of catalog contents.
  end
end
