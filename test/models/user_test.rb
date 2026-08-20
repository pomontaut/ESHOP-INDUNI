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
end
