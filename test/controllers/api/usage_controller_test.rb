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

  test "daily report is emailed once after 16h00 and only with activity" do
    travel_to UsageReport::ZONE.local(2026, 3, 4, 10, 0) do # mercredi ouvré
      login(users(:two))
      post "/api/usage/events", params: batch("tok-2", [ ev("visit") ]), as: :json
      zone = UsageReport::ZONE
      early = zone.local(2026, 3, 4, 12, 0)
      late  = zone.local(2026, 3, 4, 16, 30)

      assert_no_emails { UsageReport.run_due!(early) }
      assert_emails(User::PERMANENT_ADMIN_EMAILS.size) { UsageReport.run_due!(late) }
      assert_no_emails { UsageReport.run_due!(late) }
    end
  end

  test "daily report is never sent on weekends or Geneva public holidays" do
    travel_to UsageReport::ZONE.local(2026, 3, 7, 10, 0) do # samedi
      login(users(:two))
      post "/api/usage/events", params: batch("tok-3", [ ev("visit") ]), as: :json
      assert_no_emails { UsageReport.run_due!(UsageReport::ZONE.local(2026, 3, 7, 17, 0)) }
    end
  end

  test "Geneva public holidays" do
    h2026 = UsageReport.geneva_holidays(2026)
    [ [ 1, 1 ], [ 4, 3 ], [ 4, 6 ], [ 5, 14 ], [ 5, 25 ], [ 8, 1 ], [ 9, 10 ], [ 12, 25 ], [ 12, 31 ] ].each do |m, d|
      assert_includes h2026, Date.new(2026, m, d)
    end
    assert_includes UsageReport.geneva_holidays(2027), Date.new(2027, 9, 9) # Jeûne genevois
    assert UsageReport.working_day?(Date.new(2026, 3, 4))
    assert_not UsageReport.working_day?(Date.new(2026, 3, 8))
    assert_not UsageReport.working_day?(Date.new(2026, 4, 6))
  end

  test "indicators: search mode, keyword types, time to cart, attendance, search-agent leads" do
    login(users(:two))
    t0 = Time.current - 5.minutes
    post "/api/usage/events", params: batch("tok-i", [
      ev("visit", {}, t0),
      ev("search", { q: "tuyau 125", results: 0, via: "recherche" }, t0 + 5.seconds),
      ev("search", { q: "tuyau", results: 20, via: "recherche" }, t0 + 15.seconds),
      ev("search", { q: "52100234", results: 1, via: "recherche" }, t0 + 25.seconds),
      ev("click", { via: "recherche" }, t0 + 30.seconds),
      ev("add_to_cart", { article: "A1", catalog: "HG COMMERCIALE", designation: "Tuyau PVC", via: "recherche" }, t0 + 40.seconds),
      ev("click", { via: "liste" }, t0 + 60.seconds),
      ev("add_to_cart", { article: "B2", catalog: "HG COMMERCIALE", designation: "Coude", via: "liste" }, t0 + 80.seconds),
      ev("add_to_cart", { article: "C3", catalog: "HG COMMERCIALE", designation: "Reprise", via: "reprise" }, t0 + 90.seconds)
    ], active: 120, clicks: 2), as: :json
    login(users(:one))
    get "/api/usage/indicators", params: { days: 7 }
    assert_response :success
    r = JSON.parse(response.body)
    assert_equal 1, r["attendance"]["users_connected"]
    assert_equal 120, r["attendance"]["avg_active_per_user_day"]
    types = r["search"]["keyword_types"].index_by { |t| t["key"] }
    assert_equal 1, types["mot_dimension"]["n"]
    assert_equal 1, types["mot_seul"]["n"]
    assert_equal 1, types["reference"]["n"]
    assert_equal 1, r["search"]["zero_results"]
    assert_equal 3, r["search"]["time_to_cart"]["carts"]
    assert_equal 1, r["search"]["time_to_cart"]["carts_with_search"]
    assert_equal 35, r["search"]["time_to_cart"]["avg_seconds"]
    assert_equal 1, r["search"]["adds_via"]["reprise"]["n"]
    assert_includes r["keyword_leads"].map { |l| l["q"] }, "tuyau 125"
    login(users(:two))
    get "/api/usage/indicators"
    assert_response :forbidden
  end

  test "keyword_type classification" do
    refs = Set.new([ "hg-1234" ])
    sw = Set.new(%w[canplast sika])
    { "hg-1234" => "reference", "52100234" => "reference", "dn100" => "dimension", "160x80" => "dimension", "110" => "dimension",
      "sika" => "fournisseur", "tuyau 125" => "mot_dimension", "coude" => "mot_seul", "raccord en y" => "phrase" }.each do |q, t|
      assert_equal t, UsageReport.keyword_type(q, refs, sw), q
    end
  end

  test "an order without any measured cart add is flagged (command not seen by the agent)" do
    u = users(:two)
    login(u)
    post "/api/usage/events", params: batch("tok-o", [ ev("visit"), ev("search", { q: "coude", results: 5, via: "recherche" }) ]), as: :json
    order = Order.create!(user: u, supplier: suppliers(:one), status: "sent", notes: "Chantier: X")
    report = UsageReport.build(UsageReport::ZONE.today)
    assert_equal 1, report[:orders]
    assert_equal 1, report[:orders_untraced].size
    assert_includes report[:orders_untraced].first[:reason], "aucun ajout"
    assert(report[:observations].any? { |o| o.include?(order.number.to_s) })
    # un utilisateur sans aucune mesure mais avec une commande est aussi signalé
    Order.create!(user: users(:one), supplier: suppliers(:one), status: "sent")
    assert_equal 1, UsageReport.build(UsageReport::ZONE.today)[:orders_untraced].size # admin non suivi
  end
end
