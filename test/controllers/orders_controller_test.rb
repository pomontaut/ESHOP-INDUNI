require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { email: users(:one).email, password: "password123" }
    @order = orders(:one)
  end

  test "should get index" do
    get orders_url
    assert_response :success
  end

  test "should get show" do
    get order_url(@order)
    assert_response :success
  end

  test "should get new" do
    get new_order_url
    assert_response :success
  end

  test "should get edit" do
    get edit_order_url(@order)
    assert_response :success
  end

  test "a non-admin cannot open, list or modify an order of a chantier that is not theirs" do
    supplier = Supplier.create!(name: "Fournisseur page commandes")
    foreign = Order.create!(supplier: supplier, user: users(:one), notes: "Chantier: 99999-Pas à moi | Délai souhaité: X")
    user = users(:two)
    user.update!(admin: false, chantier_access_scope: "own")

    delete logout_url
    post login_url, params: { email: user.email, password: "password123" }

    get orders_url
    assert_response :success
    assert_not_includes response.body, foreign.number

    get order_url(foreign)
    assert_response :not_found
    delete order_url(foreign)
    assert_response :not_found
    assert Order.exists?(foreign.id)
  end
end
