require "test_helper"

class Api::UsageControllerTest < ActionDispatch::IntegrationTest
  def login(user) = post(login_url, params: { email: user.email, password: "password123" })

  def batch(token, events, active: 0, clicks: 0)
    { session: token, active_seconds: active, clicks: clicks, events: events }
  end

  def ev(kind, data = {}, at = Time.current)
    { k: kind, t: (at.to_f * 1000).to_i, d: data }
  end

  test "tracked user events are stored and become a journey in the daily report" do
    login(users(:two))
    t0 = Time.current - 90.seconds
    post "/api/usage/events", params: batch("tok-1", [
      ev("visit", { view: "home" }, t0),
      ev("search", { q: "tuyau 125", results: 0, via: "recherche" }, t0 + 5.seconds),
      ev("search", { q: "tuyau pvc 125", results: 12, via: "recherche" }, t0 + 20.seconds),
      ev("click", { via: "recherche", text: "Ajouter" }, t0 + 40.seconds),
      ev("add_to_cart", { article: "A1", catalog: "HG COMMERCIALE", designation: "Tuyau", via: "recherche" }, t0 + 60.seconds),
      ev("hack", { q: "x" }, t0)
    ], active: 70, clicks: 1), as: :json
    assert_response :no_content
    assert_equal 5, UsageEvent.where(user_id: users(:two).id).where.not(kind: "login").count
    assert_equal 70, UsageSession.find_by(token: "tok-1").active_seconds

    login(users(:one))
    get "/api/usage/report", params: { date: UsageReport::ZONE.today.iso8601 }
    assert_response :success
    report = JSON.parse(response.body)
    u = report["users"].find { |x| x["name"] == users(:two).full_name }
    assert_equal 1, u["sessions"]
    assert_equal 1, u["adds"]
    assert_equal 1, u["zero_results"]
    assert_equal "tuyau 125", u["first_queries"].first
    assert_equal 55, u["avg_seconds_to_cart"]
    assert_equal({ "recherche" => 1 }, u["vias"])
    assert_includes report["zero_result_queries"].map(&:first), "tuyau 125"
  end

  test "administrators and purchasing staff are never tracked" do
    login(users(:one))
    post "/api/usage/events", params: batch("tok-admin", [ ev("visit") ]), as: :json
    assert_response :no_content
    assert_equal 0, UsageEvent.count

    buyer = User.create!(email: "acheteur@induni.ch", password: "password123", first_name: "A", last_name: "B", job_function: "ACHETEUR")
    refute buyer.usage_tracked?
    assert User.new(sector: "SERVICE ACHATS").tap { |u| u.email = "d@induni.ch" }.usage_tracked? == false
    assert users(:two).usage_tracked?
  end

  test "report and send_report are admin only" do
    login(users(:two))
    get "/api/usage/report"
    assert_response :forbidden
    post "/api/usage/send_report"
    assert_response :forbidden
  end

  test "login of a tracked user is recorded and me exposes the flag" do
    post login_url, params: { email: users(:two).email, password: "password123" }
    assert_equal 1, UsageEvent.where(kind: "login", user_id: users(:two).id).count
    get "/api/me"
    assert_equal true, JSON.parse(response.body)["usage_tracking"]
  end

  test "daily report is emailed once after 18h30 and only with activity" do
    login(users(:two))
    post "/api/usage/events", params: batch("tok-2", [ ev("visit") ]), as: :json
    zone = UsageReport::ZONE
    early = zone.local(zone.today.year, zone.today.month, zone.today.day, 12, 0)
    late  = zone.local(zone.today.year, zone.today.month, zone.today.day, 19, 0)

    assert_no_emails { UsageReport.run_due!(early) }
    assert_emails(User::PERMANENT_ADMIN_EMAILS.size) { UsageReport.run_due!(late) }
    assert_no_emails { UsageReport.run_due!(late) }
  end
end
