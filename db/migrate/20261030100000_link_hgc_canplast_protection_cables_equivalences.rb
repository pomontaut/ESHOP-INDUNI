class LinkHgcCanplastProtectionCablesEquivalences < ActiveRecord::Migration[8.1]
  # Protection câbles : équivalences HGC <-> Canplast à DIAMÈTRE EXACT et même longueur
  # (jamais un arrondi nominal). Clé = n° d'article HGC, partagée avec le(s) article(s) Canplast.
  # Tuyaux LDPE manchonnés KRSEM = CL-PE (L5 / L10), coudes KRB-H Ø60-120 = coudes flexibles LISSES CLPECFL (45° court / 90° long, validé),
  # manchons doubles KRDM = CL-PEMD, séries K Swisscom (K55 L5/L10, K100 souple/dur, coude K55 R600)
  # et coudes Varioflex = coudes flexibles longs 90°.
  LINKS = {
    "100075094" => [%w[100075094 100033022], %w[CLPE0720605]],
    "100075096" => [%w[100075096], %w[CLPE0920805]],
    "100075098" => [%w[100075098], %w[CLPE1121005]],
    "100075100" => [%w[100075100], %w[CLPE1321205]],
    "100075102" => [%w[100075102], %w[CLPE1631485]],
    "100075095" => [%w[100075095], %w[CLPE07206010]],
    "100075097" => [%w[100075097], %w[CLPE09208010]],
    "100075099" => [%w[100075099], %w[CLPE11210010]],
    "100075101" => [%w[100075101], %w[CLPE13212010]],
    "100075103" => [%w[100075103], %w[CLPE16314810]],
    "100075403" => [%w[100075403], %w[CLPEMD072]],
    "100075404" => [%w[100075404], %w[CLPEMD092]],
    "100075405" => [%w[100075405], %w[CLPEMD112]],
    "100075406" => [%w[100075406 100098859], %w[CLPEMD132]],
    "100075407" => [%w[100075407], %w[CLPEMD163]],
    "100075408" => [%w[100075408], %w[CLPEMD214]],
    "100053899" => [%w[100053899], %w[CLPEK555]],
    "100053921" => [%w[100053921], %w[CLPEK55]],
    "100053923" => [%w[100053923], %w[CLPEK100]],
    "100053929" => [%w[100053929], %w[CLPEK100D]],
    "100053954" => [%w[100053954], %w[CLPEK55CL]],
    "100033489" => [%w[100033489], %w[CLPECF07290]],
    "100033515" => [%w[100033515], %w[CLPECF13290]],
    "100075420" => [%w[100075420], %w[CLPECFL07245]],
    "100075421" => [%w[100075421], %w[CLPECFL09245]],
    "100075422" => [%w[100075422], %w[CLPECFL11245]],
    "100075423" => [%w[100075423], %w[CLPECFL13245]],
    "100075414" => [%w[100075414], %w[CLPECFL07290]],
    "100075415" => [%w[100075415], %w[CLPECFL09290]],
    "100075416" => [%w[100075416], %w[CLPECFL11290]],
    "100075417" => [%w[100075417], %w[CLPECFL13290]],
  }.freeze

  def up
    LINKS.each do |key, (hgc_refs, canplast_refs)|
      { "HG COMMERCIALE" => hgc_refs, "Canplast" => canplast_refs }.each do |name, refs|
        supplier = Supplier.find_by(name: name) or next
        Product.where(supplier_id: supplier.id, reference: refs).update_all(equivalence_key: key)
      end
    end
  end

  def down
    # Données de référence : pas de retour arrière.
  end
end
