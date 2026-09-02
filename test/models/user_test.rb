require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "effective_visible_suppliers returns everything for an admin" do
    admin = users(:one)
    assert admin.admin?
    assert_equal Supplier.pluck(:name).sort, admin.effective_visible_suppliers.sort
  end

  test "effective_visible_suppliers excludes a supplier restricted to a different sector" do
    user = users(:two)
    user.update!(sector: "BAT VD")
    restricted = suppliers(:one)
    restricted.update!(name: "Fournisseur restreint", visible_sectors: [ "BAT GE" ])

    assert_not user.effective_visible_suppliers.include?(restricted.name)
  end

  test "effective_visible_suppliers includes an unrestricted supplier regardless of sector" do
    user = users(:two)
    user.update!(sector: "BAT VD")
    unrestricted = suppliers(:two)
    unrestricted.update!(name: "Fournisseur ouvert", visible_sectors: [])

    assert user.effective_visible_suppliers.include?(unrestricted.name)
  end

  test "effective_visible_suppliers intersects sector rules with a manual override" do
    restricted = suppliers(:one)
    restricted.update!(name: "Fournisseur restreint", visible_sectors: [ "BAT VD" ]) # not this user's sector
    allowed = suppliers(:two)
    allowed.update!(name: "Fournisseur autorisé")
    user = users(:two)
    user.update!(sector: "BAT GE", allowed_suppliers: [ restricted.name, allowed.name ])

    result = user.effective_visible_suppliers
    assert_not result.include?(restricted.name)
    assert result.include?(allowed.name)
  end

  test "effective_visible_suppliers treats a blank-only allowed_suppliers as no manual restriction" do
    # The admin form's hidden "" fallback (so an all-unchecked submission
    # still sends the param) used to be saved verbatim as allowed_suppliers:
    # [""] — a non-empty array with no real entries, which intersected to
    # nothing and emptied every catalog for the user. A real report from
    # production: "ces catalogues sont vides" for every single supplier.
    user = users(:two)
    user.update!(allowed_suppliers: [ "" ])

    assert_equal Supplier.pluck(:name).sort, user.effective_visible_suppliers.sort
  end

  test "chantier_access_label reports full access for an admin" do
    admin = users(:one)
    assert_equal "Tous les chantiers Induni (compte administrateur)", admin.chantier_access_label
  end

  test "chantier_access_label reports the sector for a non-admin on the secteur scope" do
    user = users(:two)
    user.update!(admin: false, chantier_access_scope: "secteur", sector: "GC")
    assert_equal "Tous les chantiers du secteur GC", user.chantier_access_label
  end

  test "chantier_access_label flags a missing sector on the secteur scope" do
    user = users(:two)
    user.update!(admin: false, chantier_access_scope: "secteur", sector: nil)
    assert_equal "Secteur non défini — repli sur ses propres chantiers uniquement", user.chantier_access_label
  end

  test "chantier_access_label reports own-chantiers-only by default" do
    user = users(:two)
    user.update!(admin: false, chantier_access_scope: "own")
    assert_match(/propres chantiers/, user.chantier_access_label)
  end
end
