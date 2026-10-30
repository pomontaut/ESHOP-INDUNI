class LinkHgcCanplastProtectionCablesEquivalences < ActiveRecord::Migration[8.1]
  # Équivalences HGC ↔ Canplast « Protection Câbles » validées par le propriétaire
  # (tableau docs/equivalences_protection_cables_HGC_Canplast.xlsx, lignes « ok »).
  # Seuls les Ø intérieur ET extérieur identiques (ou K55 Ø63 / rapprochements déjà
  # admis) sont liés ; clé = n° d'article HGC, posée des deux côtés.
  PAIRS = {
    "100053954" => "CLPEK55CL",
    "100033489" => "CLPECF07290",
    "100033515" => "CLPECF13290",
    "100075403" => "CLPEMD072",
    "100075404" => "CLPEMD092",
    "100075405" => "CLPEMD112",
    "100075406" => "CLPEMD132",
    "100075084" => "CLPEMEX072",
    "100075085" => "CLPEMEX092",
    "100075086" => "CLPEMEX112",
    "100075087" => "CLPEMEX132",
    "100053951" => "CLPEK55MEX"
  }.freeze

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    canplast = Supplier.find_by(name: "Canplast")
    return unless hgc && canplast

    PAIRS.each do |hgc_ref, canplast_ref|
      Product.where(supplier_id: hgc.id, reference: hgc_ref).update_all(equivalence_key: hgc_ref)
      Product.where(supplier_id: canplast.id, reference: canplast_ref).update_all(equivalence_key: hgc_ref)
    end
  end

  def down
    # Data refresh only — no rollback of catalog contents.
  end
end
