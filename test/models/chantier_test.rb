require "test_helper"

class ChantierTest < ActiveSupport::TestCase
  test "visible_to returns every chantier for an admin" do
    Chantier.create!(nom: "A")
    Chantier.create!(nom: "B")
    admin = users(:one)
    admin.update!(admin: true)

    assert_equal Chantier.count, Chantier.visible_to(admin).count
  end

  test "visible_to returns nothing for no user" do
    Chantier.create!(nom: "A")
    assert_equal 0, Chantier.visible_to(nil).count
  end

  test "visible_to defaults to only the chantiers where the user's e-mail is a contact" do
    user = users(:two)
    user.update!(admin: false, chantier_access_scope: "own")
    mine = Chantier.create!(nom: "Mine", email_technicien: user.email)
    Chantier.create!(nom: "Not mine", email_technicien: "someone.else@induni.ch")

    result = Chantier.visible_to(user)
    assert_equal [ mine ], result.to_a
  end

  test "visible_to with the secteur scope returns every chantier sharing the user's sector" do
    user = users(:two)
    user.update!(admin: false, chantier_access_scope: "secteur", sector: "GC")
    same_sector = Chantier.create!(nom: "GC chantier", secteur: "GC")
    other_sector = Chantier.create!(nom: "BAT GE chantier", secteur: "BAT GE")

    result = Chantier.visible_to(user)
    assert_includes result, same_sector
    assert_not_includes result, other_sector
  end

  test "visible_to falls back to own chantiers when secteur scope is set but the user has no sector" do
    user = users(:two)
    user.update!(admin: false, chantier_access_scope: "secteur", sector: nil)
    mine = Chantier.create!(nom: "Mine", email_technicien: user.email)
    Chantier.create!(nom: "Some sector chantier", secteur: "GC")

    result = Chantier.visible_to(user)
    assert_equal [ mine ], result.to_a
  end
end
