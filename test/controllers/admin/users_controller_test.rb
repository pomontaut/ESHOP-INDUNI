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
end
