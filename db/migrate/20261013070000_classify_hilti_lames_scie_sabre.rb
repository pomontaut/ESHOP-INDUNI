class ClassifyHiltiLamesScieSabre < ActiveRecord::Migration[8.0]
  # Les 21 lames de scie sabre HILTI (sous-famille "Lame") sont réparties par
  # modèle (SP / SPX / P, lisible dans la désignation) puis, au sein de
  # chaque modèle, par type (universel / w-m — bois avec clous) : voir
  # ClassifyHiltiLamesScieSabre::DATA ci-dessous.
  #
  # Le chiffre entre parenthèses dans la désignation d'origine (ex.
  # "(35) univ") est le conditionnement (nombre de lames par boîte), pas une
  # variante produit : il est retiré de la désignation et déplacé dans
  # descriptif ("Cond. 35 pce"), pour s'afficher comme sur les autres
  # catalogues (ex. EFCO) plutôt que de rester une parenthèse peu lisible.
  DATA = {
    "2270773" => { sous_sous_famille: "Lame scie sabre SPX", descriptif: "Cond. 10 pce",  name: "Lame de scie sabre SPX 15 68 univ" },
    "2140379" => { sous_sous_famille: "Lame scie sabre SPX", descriptif: "Cond. 10 pce",  name: "Lame de scie sabre SPX 23 68 univ" },
    "2140721" => { sous_sous_famille: "Lame scie sabre SPX", descriptif: "Cond. 10 pce",  name: "Lame de scie sabre SPX 30 68 univ" },
    "2267009" => { sous_sous_famille: "Lame scie sabre SP",  descriptif: "Cond. 35 pce",  name: "Lame de scie sabre SP 15 1014 univ" },
    "2267011" => { sous_sous_famille: "Lame scie sabre SP",  descriptif: "Cond. 35 pce",  name: "Lame de scie sabre SP 20 1014 univ" },
    "2267012" => { sous_sous_famille: "Lame scie sabre SP",  descriptif: "Cond. 175 pce", name: "Lame de scie sabre SP 20 1014 univ" },
    "2267013" => { sous_sous_famille: "Lame scie sabre SP",  descriptif: "Cond. 5 pce",   name: "Lame de scie sabre SP 30 1014 univ" },
    "2222118" => { sous_sous_famille: "Lame scie sabre P",   descriptif: "Cond. 45 pce",  name: "Lame de scie sabre P 15 1014 univ" },
    "2222121" => { sous_sous_famille: "Lame scie sabre P",   descriptif: "Cond. 200 pce", name: "Lame de scie sabre P 15 1014 univ" },
    "2222119" => { sous_sous_famille: "Lame scie sabre P",   descriptif: "Cond. 45 pce",  name: "Lame de scie sabre P 20 1014 univ" },
    "2222120" => { sous_sous_famille: "Lame scie sabre P",   descriptif: "Cond. 200 pce", name: "Lame de scie sabre P 20 1014 univ" },
    "2222124" => { sous_sous_famille: "Lame scie sabre P",   descriptif: "Cond. 45 pce",  name: "Lame de scie sabre P 23 1014 univ" },
    "2222127" => { sous_sous_famille: "Lame scie sabre P",   descriptif: "Cond. 200 pce", name: "Lame de scie sabre P 23 1014 univ" },
    "2262671" => { sous_sous_famille: "Lame scie sabre SPX", descriptif: "Cond. 10 pce",  name: "Lame de scie sabre SPX 15 57 w/m" },
    "2262673" => { sous_sous_famille: "Lame scie sabre SPX", descriptif: "Cond. 10 pce",  name: "Lame de scie sabre SPX 23 57 w/m" },
    "2262137" => { sous_sous_famille: "Lame scie sabre SPX", descriptif: "Cond. 10 pce",  name: "Lame de scie sabre SPX 30 57 w/m" },
    "2222125" => { sous_sous_famille: "Lame scie sabre SP",  descriptif: "Cond. 35 pce",  name: "Lame de scie sabre SP 15 6 w/m" },
    "2222129" => { sous_sous_famille: "Lame scie sabre SP",  descriptif: "Cond. 35 pce",  name: "Lame de scie sabre SP 23 6 w/m" },
    "2222130" => { sous_sous_famille: "Lame scie sabre SP",  descriptif: "Cond. 175 pce", name: "Lame de scie sabre SP 23 6 w/m" },
    "2222131" => { sous_sous_famille: "Lame scie sabre SP",  descriptif: "Cond. 5 pce",   name: "Lame de scie sabre SP 30 6 w/m" },
    "2222132" => { sous_sous_famille: "Lame scie sabre SP",  descriptif: "Cond. 35 pce",  name: "Lame de scie sabre SP 30 6 w/m" }
  }.freeze

  def up
    hilti = Supplier.find_by(name: "HILTI")
    return unless hilti

    DATA.each do |reference, attrs|
      Product.where(supplier: hilti, reference: reference).update_all(attrs)
    end
  end

  def down
    # Non réversible proprement (désignation/descriptif réécrits) : no-op délibéré.
  end
end
