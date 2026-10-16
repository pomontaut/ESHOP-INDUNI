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

  test "visible_to also includes chantiers explicitly assigned to the user" do
    user = users(:two)
    user.update!(admin: false, chantier_access_scope: "own")
    assigned = Chantier.create!(nom: "Assigned")
    Chantier.create!(nom: "Other")
    ChantierAssignment.create!(user: user, chantier: assigned)

    assert_equal [ assigned ], Chantier.visible_to(user).to_a
  end

  test "matching_person finds chantiers by name in any order, ignoring accents and case" do
    a = Chantier.create!(nom: "A", technicien: "Jean-Luc Dupont")
    b = Chantier.create!(nom: "B", contremaitre: "DUPONT Jean-Luc", chef_equipe: "Autre Personne")
    Chantier.create!(nom: "C", technicien: "Jean Martin")

    found = Chantier.matching_person("Jean-Luc", "Dupont")
    assert_equal [ a, b ], found.map { |m| m[:chantier] }
    assert_equal [ [ "Technicien" ], [ "Contremaître" ] ], found.map { |m| m[:roles] }
    assert_empty Chantier.matching_person("Zoé", "Inconnue")
  end

  test "visible_to also gives access through an additional contact's e-mail (technician, foreman, team lead) but not a delivery contact" do
    user = users(:two)
    user.update!(admin: false, chantier_access_scope: "own")
    via_tech = Chantier.create!(nom: "Via technicien suppl.")
    via_tech.contacts.create!(role: "technicien", nom: "Autre Tech", email: user.email.upcase)
    via_livraison = Chantier.create!(nom: "Via contact livraison")
    via_livraison.contacts.create!(role: "contact_livraison", nom: "Réception", email: user.email)
    Chantier.create!(nom: "Aucun lien")

    assert_equal [ via_tech ], Chantier.visible_to(user).to_a
  end

  test "matching_person also finds a person listed as an additional contact" do
    chantier = Chantier.create!(nom: "Équipe étendue", technicien: "MORAND Adrien")
    chantier.contacts.create!(role: "contremaitre", nom: "GAILLARD Cédric")

    found = Chantier.matching_person("Cédric", "Gaillard")
    assert_equal [ chantier ], found.map { |m| m[:chantier] }
    assert_equal [ "Contremaître" ], found.first[:roles]
  end

  test "team_json lists every technician and e-mail, and delivery contacts with the primary first" do
    c = Chantier.create!(nom: "JSON", technicien: "A Un", email_technicien: "a@induni.ch", contact_livraison: "Réception Un", natel_livraison: "+411")
    c.contacts.create!(role: "technicien", nom: "B Deux", email: "b@induni.ch")
    c.contacts.create!(role: "contact_livraison", nom: "Réception Deux", natel: "+412")
    json = c.reload.team_json
    assert_equal [ "A Un", "B Deux" ], json[:techniciens]
    assert_equal [ "a@induni.ch", "b@induni.ch" ], json[:emailsTechnicien]
    assert_equal [ "Réception Un", "Réception Deux" ], json[:contactsLivraison].map { |x| x[:nom] }
  end
end
