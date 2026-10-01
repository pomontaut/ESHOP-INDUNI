require "test_helper"

class PortailTest < ActionDispatch::IntegrationTest
  def login(user) = post(login_url, params: { email: user.email, password: "password123" })

  test "un utilisateur sans accès achats est refusé" do
    login(users(:two))
    get portail_url
    assert_redirected_to root_path
  end

  test "l'admin voit le portail et les projets en cours" do
    login(users(:one))
    Projet.create!(nom: "Projet Alpha")
    Projet.create!(nom: "Projet Clos", statut: "clos")
    get portail_url
    assert_response :success
    assert_includes response.body, "Projet Alpha"
    assert_not_includes response.body, "Projet Clos"
    assert_includes response.body, "Évaluation fournisseur"
  end

  test "création d'un projet puis enregistrement de sa séance de lancement" do
    login(users(:one))
    post projets_url, params: { projet: { nom: "Projet Beta", numero: "2026-001" } }
    projet = Projet.find_by!(nom: "Projet Beta")
    assert_redirected_to projet_url(projet)

    get projet_url(projet)
    assert_includes response.body, "Séance de lancement achat"

    patch projet_seance_lancement_url(projet), params: { seance_lancement: { budget_cible: "125000", realisee: "1", decisions: "Go" } }
    seance = projet.reload.seance_lancement
    assert_equal 125_000, seance.budget_cible
    assert seance.realisee?
    assert_equal "Go", seance.decisions
  end
end
