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
end
