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
end
