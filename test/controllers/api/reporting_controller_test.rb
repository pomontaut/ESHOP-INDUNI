require "test_helper"

class Api::ReportingControllerTest < ActionDispatch::IntegrationTest
  test "articles : un admin obtient le reporting à la maille article" do
    post login_url, params: { email: users(:one).email, password: "password123" }
    get api_reporting_articles_url
    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json.keys, "articles"
    assert_includes json.keys, "kpis"
    assert_includes json["orders"].first.keys, "items"
  end

  test "articles : refusé sans le droit Analyse" do
    post login_url, params: { email: users(:two).email, password: "password123" }
    get api_reporting_articles_url
    assert_response :forbidden
  end

  test "articles : exige une connexion" do
    get api_reporting_articles_url
    assert_response :unauthorized
  end

  test "sla : jeton requis, 503 si non configuré" do
    ENV.delete("SLA_REPORTING_TOKEN")
    get api_reporting_sla_url
    assert_response :service_unavailable
  end

  test "sla : jeton invalide refusé, jeton valide accepté" do
    ENV["SLA_REPORTING_TOKEN"] = "secret-test"
    get api_reporting_sla_url, headers: { "Authorization" => "Bearer faux" }
    assert_response :unauthorized
    get api_reporting_sla_url, headers: { "Authorization" => "Bearer secret-test" }
    assert_response :success
  ensure
    ENV.delete("SLA_REPORTING_TOKEN")
  end

  test "sla : prix confidentiels masqués, quantités conservées" do
    ENV["SLA_REPORTING_TOKEN"] = "secret-test"
    supplier = suppliers(:one)
    supplier.update_columns(confidential_pricing: true, name: "Confidentiel Test")
    get api_reporting_sla_url, headers: { "Authorization" => "Bearer secret-test" }
    json = JSON.parse(response.body)
    rows = json["articles"].select { |a| a["supplier"] == supplier.name }
    assert rows.any?
    rows.each do |a|
      assert_nil a["amount"]
      assert_nil a["avgPrice"]
      assert_nil a["gain"]
      assert a["qty"].positive?
    end
    json["orders"].select { |o| o["supplier"] == supplier.name }.each do |o|
      assert_nil o["total"]
      o["items"].each { |i| assert_nil i["unitPrice"] }
    end
  ensure
    ENV.delete("SLA_REPORTING_TOKEN")
  end
end

class ArticleReportTest < ActiveSupport::TestCase
  test "exclut les commandes annulées et de test, agrège quantités et montants" do
    order = orders(:one)
    order.update_columns(cancelled_at: Time.current, number: "ESHOP_INDUNI_901")
    report = ArticleReport.new(scope: Order.all, show_confidential: true).as_json
    assert_not_includes report[:orders].map { |o| o[:no] }, order.number
    assert_equal 1, report[:kpis][:nbCancelled]

    order.update_columns(cancelled_at: nil, sent_subject: "[TEST] x")
    report = ArticleReport.new(scope: Order.all, show_confidential: true).as_json
    assert_equal 1, report[:kpis][:nbOrdersAll]
  end
end
