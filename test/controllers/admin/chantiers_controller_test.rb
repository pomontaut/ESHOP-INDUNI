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

  test "create persists the dedicated delivery contact" do
    post admin_chantiers_url, params: {
      chantier: { nom: "Nouveau chantier", contact_livraison: "PINTO Pedro", natel_livraison: "+41763656892", email_livraison: "ppinto@induni.ch" }
    }

    chantier = Chantier.find_by!(nom: "Nouveau chantier")
    assert_equal "PINTO Pedro", chantier.contact_livraison
    assert_equal "+41763656892", chantier.natel_livraison
    assert_equal "ppinto@induni.ch", chantier.email_livraison
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

  test "index search works by keywords in any order, across name, city and contacts, ignoring accents and case" do
    halle = Chantier.create!(nom: "12601-Halle des Rouettes", ville: "Vernier", npa: "1214", technicien: "Joni Pessoa")
    Chantier.create!(nom: "12501-Caran d'Ache", ville: "Genève", npa: "1227", contremaitre: "Zoé Martin")

    get admin_chantiers_url, params: { q: "vernier HALLE" }
    assert_select "td", text: /12601-Halle des Rouettes/
    assert_select "td", text: /Caran/, count: 0

    get admin_chantiers_url, params: { q: "zoe genève" }
    assert_select "td", text: /Caran d'Ache/
    assert_select "td", text: /Halle des Rouettes/, count: 0

    get admin_chantiers_url, params: { q: "pessoa 1214" }
    assert_select "td", text: /Halle des Rouettes/

    get admin_chantiers_url, params: { q: "halle caran" }
    assert_select "td", text: /Halle|Caran/, count: 0
    assert halle.persisted?
  end

  test "create and update persist several technicians, foremen, team leads and delivery contacts" do
    post admin_chantiers_url, params: {
      chantier: { nom: "Gros chantier", technicien: "MORAND Adrien", email_technicien: "amorand@induni.ch",
        contacts_attributes: {
          "0" => { role: "technicien", nom: "DUPONT Jean", natel: "+41790000001", email: "JDupont@induni.ch" },
          "1" => { role: "contremaitre", nom: "GAILLARD Cédric", email: "cgaillard@induni.ch" },
          "2" => { role: "contact_livraison", nom: "PINTO Pedro", natel: "+41763656892" },
          "3" => { role: "chef_equipe", nom: "", natel: "", email: "" } # ligne vide ignorée
        } }
    }
    chantier = Chantier.find_by!(nom: "Gros chantier")
    assert_equal 3, chantier.contacts.count
    assert_equal [ "MORAND Adrien", "DUPONT Jean" ], chantier.technicien_names
    assert_equal [ "amorand@induni.ch", "jdupont@induni.ch" ], chantier.technicien_emails

    # ✕ sur une personne existante = suppression ; champs vidés = suppression aussi
    dupont, gaillard = chantier.contacts_for("technicien").first, chantier.contacts_for("contremaitre").first
    patch admin_chantier_url(chantier), params: { chantier: { contacts_attributes: {
      "0" => { id: dupont.id, role: "technicien", nom: "DUPONT Jean", _destroy: "1" },
      "1" => { id: gaillard.id, role: "contremaitre", nom: "", natel: "", email: "" }
    } } }
    assert_equal [ "PINTO Pedro" ], chantier.reload.contacts.map(&:nom)
  end

  test "edit form renders an add button for each of the four roles" do
    chantier = Chantier.create!(nom: "Formulaire")
    get edit_admin_chantier_url(chantier)
    assert_response :success
    %w[technicien contremaitre chef_equipe contact_livraison].each do |role|
      assert_select "[data-extra-role='#{role}'] .extra-add"
    end
  end
end
