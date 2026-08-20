require "test_helper"

class Api::DieselPricesControllerTest < ActionDispatch::IntegrationTest
  test "index requires authentication" do
    get api_diesel_prices_url
    assert_response :unauthorized
  end

  test "index returns the weekly history ordered with the surcharge percentage" do
    DieselPrice.delete_all
    DieselPrice.create!(week_start: "2026-08-10", price: 2.15)
    DieselPrice.create!(week_start: "2026-08-17", price: 2.19)
    post login_url, params: { email: users(:one).email, password: "password123" }

    get api_diesel_prices_url
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [ "2026-08-10", "2026-08-17" ], body.map { |r| r["weekStart"] }
    assert_in_delta 33.54, body.last["surchargePct"], 0.1
  end

  test "create refuses a non-admin" do
    DieselPrice.delete_all
    post login_url, params: { email: users(:two).email, password: "password123" }
    post api_diesel_prices_url, params: { price: "2.20" }
    assert_response :forbidden
  end

  test "create lets an admin upsert the current week's price" do
    DieselPrice.delete_all
    post login_url, params: { email: users(:one).email, password: "password123" }

    assert_difference "DieselPrice.count", 1 do
      post api_diesel_prices_url, params: { price: "2.21" }
    end
    assert_response :success

    assert_no_difference "DieselPrice.count" do
      post api_diesel_prices_url, params: { price: "2.25" }
    end
    week_start = Date.current.beginning_of_week(:monday)
    assert_equal 2.25, DieselPrice.find_by(week_start: week_start).price.to_f
  end
end
