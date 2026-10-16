require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { email: users(:one).email, password: "password123" }
  end

  test "update persists the new feature permissions" do
    user = users(:two)

    patch admin_user_url(user), params: {
      user: {
        first_name: user.first_name, last_name: user.last_name, email: user.email,
        can_view_dashboard: "1", can_view_analysis: "1", can_view_nomenclature: "0"
      }
    }

    assert_redirected_to admin_users_path
    user.reload
    assert user.can_view_dashboard?
    assert user.can_view_analysis?
    assert_not user.can_view_nomenclature?
  end

  test "update persists the validation-de-commande and alerts display rights" do
    user = users(:two)
    assert user.can_validate_orders?, "défaut : vrai, l'interface actuelle est conservée"
    assert user.can_enable_alerts?

    patch admin_user_url(user), params: {
      user: { first_name: user.first_name, last_name: user.last_name, email: user.email,
              can_validate_orders: "0", can_enable_alerts: "0" }
    }

    user.reload
    assert_not user.can_validate_orders?
    assert_not user.can_enable_alerts?
  end

  test "update persists the chantier access scope" do
    user = users(:two)

    patch admin_user_url(user), params: {
      user: {
        first_name: user.first_name, last_name: user.last_name, email: user.email,
        sector: "GC", chantier_access_scope: "secteur"
      }
    }

    assert_redirected_to admin_users_path
    user.reload
    assert_equal "secteur", user.chantier_access_scope
    assert_equal "Tous les chantiers du secteur GC", user.chantier_access_label
  end

  test "update strips the hidden blank fallback from allowed_suppliers when no catalog checkbox is checked" do
    # The "Accès catalogues fournisseurs" checkboxes all share a trailing
    # hidden input (value: "") so an all-unchecked submission still sends
    # the allowed_suppliers param at all. Saved as-is, that blank string
    # made the array non-empty and silently emptied every catalog for the
    # user (see User#effective_visible_suppliers) — exactly what a real
    # admin hit when creating a user without touching that section.
    user = users(:two)

    patch admin_user_url(user), params: {
      user: {
        first_name: user.first_name, last_name: user.last_name, email: user.email,
        allowed_suppliers: [ "" ]
      }
    }

    assert_redirected_to admin_users_path
    assert_equal [], user.reload.allowed_suppliers
  end

  test "update refuses to promote a user to admin without the confirmation code" do
    ENV["ADMIN_PROMOTION_CODE"] = "secret-code"
    user = users(:two)

    patch admin_user_url(user), params: { user: { admin: "1" } }

    assert_response :unprocessable_entity
    assert_not user.reload.admin?
  ensure
    ENV.delete("ADMIN_PROMOTION_CODE")
  end

  test "update refuses to promote a user to admin with the wrong confirmation code" do
    ENV["ADMIN_PROMOTION_CODE"] = "secret-code"
    user = users(:two)

    patch admin_user_url(user), params: { user: { admin: "1" }, admin_confirmation_code: "wrong" }

    assert_response :unprocessable_entity
    assert_not user.reload.admin?
  ensure
    ENV.delete("ADMIN_PROMOTION_CODE")
  end

  test "update promotes a user to admin when the confirmation code matches" do
    ENV["ADMIN_PROMOTION_CODE"] = "secret-code"
    user = users(:two)

    patch admin_user_url(user), params: { user: { admin: "1" }, admin_confirmation_code: "secret-code" }

    assert_redirected_to admin_users_path
    assert user.reload.admin?
  ensure
    ENV.delete("ADMIN_PROMOTION_CODE")
  end

  test "update never requires the code when the admin status isn't changing" do
    ENV["ADMIN_PROMOTION_CODE"] = "secret-code"
    admin_user = users(:one)
    assert admin_user.admin?

    patch admin_user_url(admin_user), params: { user: { admin: "1", job_function: "Chef achats" } }

    assert_redirected_to admin_users_path
    assert_equal "Chef achats", admin_user.reload.job_function
  ensure
    ENV.delete("ADMIN_PROMOTION_CODE")
  end

  test "create refuses to create a new admin user without the confirmation code" do
    ENV["ADMIN_PROMOTION_CODE"] = "secret-code"

    assert_no_difference "User.count" do
      post admin_users_url, params: {
        user: {
          first_name: "Nouvel", last_name: "Admin", email: "nouvel.admin@induni.ch",
          password: "password123", admin: "1"
        }
      }
    end

    assert_response :unprocessable_entity
  ensure
    ENV.delete("ADMIN_PROMOTION_CODE")
  end

  test "chantier_matches suggests the chantiers where the typed name is technicien, contremaître or chef d'équipe" do
    chantier = Chantier.create!(nom: "12345-Test", chef_equipe: "Marie Curie")
    Chantier.create!(nom: "99999-Autre", technicien: "Pierre Curie")

    get chantier_matches_admin_users_url, params: { first_name: "Marie", last_name: "Curie" }

    body = JSON.parse(response.body)
    assert_equal [ chantier.id ], body.map { |m| m["id"] }
    assert_equal [ "Chef d'équipe" ], body.first["roles"]
  end

  test "create assigns the chosen chantiers to the new user" do
    c1 = Chantier.create!(nom: "C1")
    c2 = Chantier.create!(nom: "C2")

    assert_difference "User.count", 1 do
      post admin_users_url, params: {
        user: { first_name: "Nouveau", last_name: "Venu", email: "nouveau.venu@induni.ch", password: "password123",
                assigned_chantier_ids: [ "", c1.id.to_s, c2.id.to_s ] }
      }
    end

    assert_equal [ c1, c2 ].sort_by(&:id), User.find_by!(email: "nouveau.venu@induni.ch").assigned_chantiers.sort_by(&:id)
  end

  test "new and edit forms render the chantier assignment field" do
    get new_admin_user_url
    assert_select "#chantierAssignment"
    get edit_admin_user_url(users(:two))
    assert_select "#chantierAssignment"
  end
end
