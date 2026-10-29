require "test_helper"

class Api::IndicatorsControllerTest < ActionDispatch::IntegrationTest
  def login(user) = post(login_url, params: { email: user.email, password: "password123" })

  test "admin only" do
    login(users(:two))
    get "/api/indicators"
    assert_response :forbidden
  end

  test "build series, orders per day with cumulative (test orders excluded) and usage" do
    s1 = Supplier.create!(name: "HG COMMERCIALE"); s2 = Supplier.create!(name: "Canplast")
    Product.create!(supplier: s1, reference: "A", name: "A", unit_price: 1, unite: "u", famille: "F", equivalence_key: "K", image: "/images/a.jpg")
    Product.create!(supplier: s2, reference: "B", name: "B", unit_price: 1, unite: "u", famille: "F", equivalence_key: "K")
    Product.create!(supplier: s2, reference: "C", name: "C", unit_price: 1, unite: "u", famille: "F")
    Product.create!(supplier: s2, reference: "OLD", name: "Sorti", unit_price: 1, unite: "u", famille: nil)
    NomenclatureEntry.create!(induni_reference: "381100001", induni_designation: "X", supplier_name: "Canplast", supplier_reference: "B")
    zone = UsageReport::ZONE
    today = zone.today
    Order.create!(supplier: s1, number: "ESHOP_INDUNI_01", status: "sent", created_at: zone.local(today.year, today.month, today.day, 9))
    Order.create!(supplier: s1, number: "ESHOP_INDUNI_02", status: "sent", sent_subject: "[TEST] essai", created_at: zone.local(today.year, today.month, today.day, 10))
    UsageEvent.create!(user_id: users(:two).id, kind: "visit", occurred_at: Time.current)

    login(users(:one))
    get "/api/indicators", params: { from: (today - 2).iso8601 }
    assert_response :success
    j = JSON.parse(response.body)
    last = j["build"].last
    assert_equal 3, last["references"]
    assert_equal 2, last["equivalent"]
    assert_equal 1, last["induni"]
    assert_equal 2, last["catalogs"]
    assert_equal 1, last["photos"]
    assert_equal 66.7, last["equivalent_pct"]
    days = j["orders"]["days"]
    expected_today = Order.where("sent_subject IS NULL OR sent_subject NOT LIKE ?", "[TEST]%").count { |o| o.created_at.in_time_zone(zone).to_date == today }
    assert_equal expected_today, days.last["count"]
    assert_operator Order.count, :>, expected_today # la commande [TEST] n'est pas comptée
    assert_equal days.last["cumulative"], days.sum { |d| d["count"] }
    assert_equal j["orders"]["before_period"] + days.last["cumulative"], j["orders"]["total"]
    assert_equal 1, j["usage"].last["users"]
  end
end
