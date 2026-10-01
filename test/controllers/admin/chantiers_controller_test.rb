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

  test "update propagates consortium to every other Chantier row sharing the same nom" do
    # Un même chantier existe parfois sous plusieurs lignes (une par
    # combinaison technicien/contremaître/chef d'équipe, pour que
    # Chantier.visible_to donne accès au bon chantier à chacun) — toutes
    # doivent rester synchronisées sur "consortium", sans quoi le prix
    # Matériel Induni affiché dépend de la ligne que l'app choisit de lire.
    edited = Chantier.create!(nom: "12501-Caran d'Ache", chef_equipe: "A", consortium: false)
    sibling1 = Chantier.create!(nom: "12501-Caran d'Ache", chef_equipe: "B", consortium: false)
    sibling2 = Chantier.create!(nom: "12501-Caran d'Ache", chef_equipe: "C", consortium: false)
    unrelated = Chantier.create!(nom: "Autre chantier", consortium: false)

    patch admin_chantier_url(edited), params: { chantier: { nom: edited.nom, consortium: "1" } }

    assert edited.reload.consortium?
    assert sibling1.reload.consortium?, "the other row for the same chantier must follow"
    assert sibling2.reload.consortium?, "the other row for the same chantier must follow"
    assert_not unrelated.reload.consortium?, "a differently-named chantier must not be touched"
  end

  test "update does not propagate consortium when the nom itself changes" do
    edited = Chantier.create!(nom: "12501-Caran d'Ache", chef_equipe: "A", consortium: false)
    sibling = Chantier.create!(nom: "12501-Caran d'Ache", chef_equipe: "B", consortium: false)

    patch admin_chantier_url(edited), params: { chantier: { nom: "12501-Caran d'Ache (renommé)", consortium: "1" } }

    assert edited.reload.consortium?
    assert_not sibling.reload.consortium?, "a rename must not drag an unrelated nom's siblings along"
  end

  test "create persists the conducteur de travaux" do
    post admin_chantiers_url, params: {
      chantier: { nom: "Nouveau chantier", conducteur_travaux: "Jean Dupont", email_conducteur_travaux: "jdupont@induni.ch" }
    }

    chantier = Chantier.find_by!(nom: "Nouveau chantier")
    assert_equal "Jean Dupont", chantier.conducteur_travaux
    assert_equal "jdupont@induni.ch", chantier.email_conducteur_travaux
  end
end
