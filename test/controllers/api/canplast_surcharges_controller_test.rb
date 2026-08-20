require "test_helper"

class Api::CanplastSurchargesControllerTest < ActionDispatch::IntegrationTest
  test "index requires authentication" do
    get api_canplast_surcharges_url
    assert_response :unauthorized
  end

  test "index returns the surcharge history ordered by group then date" do
    CanplastSurcharge.delete_all
    CanplastSurcharge.create!(codes: "A1, A2, A3", label: "tuyaux PVC", effective_date: "2026-03-27", surcharge_pct: 59.0)
    CanplastSurcharge.create!(codes: "A1, A2, A3", label: "tuyaux PVC", effective_date: "2026-04-08", surcharge_pct: 69.0)
    CanplastSurcharge.create!(codes: "A1, A2, A3", label: "tuyaux PVC", effective_date: "2026-05-01", surcharge_pct: 71.0)
    post login_url, params: { email: users(:one).email, password: "password123" }

    get api_canplast_surcharges_url
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 3, body.length
    assert_equal [ "2026-03-27", "2026-04-08", "2026-05-01" ], body.map { |r| r["effectiveDate"] }
    assert_equal 71.0, body.last["surchargePct"]
  end

  test "create refuses a non-admin" do
    post login_url, params: { email: users(:two).email, password: "password123" }
    post api_canplast_surcharges_url, params: { codes: "A1, A2, A3", label: "test", effective_date: "2026-08-01", surcharge_pct: "75" }
    assert_response :forbidden
  end

  test "create lets an admin add a new dated entry for an existing group" do
    post login_url, params: { email: users(:one).email, password: "password123" }

    assert_difference "CanplastSurcharge.count", 1 do
      post api_canplast_surcharges_url, params: {
        codes: "A1, A2, A3", label: "tuyaux de canalisation et de drainage PVC compact",
        effective_date: "2026-08-15", surcharge_pct: "65"
      }
    end
    assert_response :success
    entry = CanplastSurcharge.find_by(codes: "A1, A2, A3", effective_date: "2026-08-15")
    assert_equal 65.0, entry.surcharge_pct.to_f
  end
end
