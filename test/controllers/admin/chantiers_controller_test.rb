require "test_helper"

class Admin::ChantiersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { email: users(:one).email, password: "password123" }
  end

  test "create persists the secteur" do
    post admin_chantiers_url, params: { chantier: { nom: "Nouveau chantier", secteur: "GC" } }

    chantier = Chantier.find_by!(nom: "Nouveau chantier")
    assert_equal "GC", chantier.secteur
  end

  test "update persists a change of secteur" do
    chantier = Chantier.create!(nom: "Chantier existant", secteur: "GC")

    patch admin_chantier_url(chantier), params: { chantier: { nom: chantier.nom, secteur: "BAT GE" } }

    assert_equal "BAT GE", chantier.reload.secteur
  end
end
