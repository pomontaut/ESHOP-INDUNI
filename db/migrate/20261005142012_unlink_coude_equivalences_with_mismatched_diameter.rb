class UnlinkCoudeEquivalencesWithMismatchedDiameter < ActiveRecord::Migration[8.1]
  # The Canplast "coude PVC SN4/SN2" equivalence was set by nominal-DN
  # rounding (Ø100→110, Ø150→160, Ø300→315, Ø350→355mm), matching the
  # standard DN-to-outer-diameter convention. Reported from the live
  # "Comparatif fournisseurs" widget: that rounding is misleading for this
  # catalog — Ø150mm and Ø160mm are not the same purchasable size, so they
  # must not be shown as interchangeable. Only the exact-diameter matches
  # (Ø125/200/250/400/500mm) are kept; the rest are unlinked (equivalence_key
  # cleared on the Canplast side only — the HGC side keeps its own reference
  # as equivalence_key, same as every other HGC article with no linked
  # equivalent).
  CANPLAST_REFERENCES_TO_UNLINK = %w[
    LDC11015 LDC11030 LDC11045 LDC11090
    LDC16015 LDC16030 LDC16045 LDC16090
    LDC31515 LDC31530 LDC31545 LDC31590
    LDC35515 LDC35530 LDC35545 LDC35590
  ].freeze

  def up
    canplast = Supplier.find_by(name: "Canplast")
    return unless canplast

    Product.where(supplier_id: canplast.id, reference: CANPLAST_REFERENCES_TO_UNLINK)
           .update_all(equivalence_key: nil)
  end

  def down
    # Data refresh only — no rollback of catalog contents.
  end
end
