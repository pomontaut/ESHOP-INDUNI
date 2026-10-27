class RenumberHgcPfeifer27mm50x20050x250 < ActiveRecord::Migration[8.0]
  # HGC (hgc.ch) a renuméroté les panneaux Pfeifer 27mm 50x200cm et 50x250cm
  # (100007004 -> 100007096, 100007006 -> 100007098) et le prix net passe de
  # 21.15 à 26.22 CHF/m2. Renommage en place : les anciennes commandes restent
  # rattachées au même article. Si le nouveau numéro existe déjà, l'ancien est
  # supprimé (ou, s'il a été commandé, retiré du catalogue).
  RENUMBER = { "100007004" => "100007096", "100007006" => "100007098" }.freeze
  NEW_PRICE = 26.22

  def up
    hgc = Supplier.find_by(name: "HG COMMERCIALE")
    return unless hgc

    RENUMBER.each do |old_ref, new_ref|
      old = Product.find_by(supplier_id: hgc.id, reference: old_ref)
      if old && Product.exists?(supplier_id: hgc.id, reference: new_ref)
        if OrderLine.exists?(product_id: old.id)
          old.update_columns(famille: nil, sous_famille: nil, sous_sous_famille: nil)
        else
          old.delete
        end
      elsif old
        old.update_columns(reference: new_ref, unit_price: NEW_PRICE)
      end
    end
  end

  def down
    # Non réversible : no-op délibéré.
  end
end
