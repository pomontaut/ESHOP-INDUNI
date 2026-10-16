require "test_helper"

class Api::HgcStockControllerTest < ActionDispatch::IntegrationTest
  # Minitest 6 n'a plus Object#stub : on remplace fetch_page le temps du bloc.
  def with_fetch_page(replacement)
    original = HgcStock.method(:fetch_page)
    HgcStock.define_singleton_method(:fetch_page, &replacement)
    yield
  ensure
    HgcStock.define_singleton_method(:fetch_page, original)
  end

  test "requires authentication" do
    get api_hgc_stock_url(article: "100014804")
    assert_response :unauthorized
  end

  test "returns the HGC availability for the given article and zip" do
    post login_url, params: { email: users(:two).email, password: "password123" }
    seen = nil
    with_fetch_page(->(article, zip) { seen = [ article, zip ]; [ '..."stockLevelStatus":{"code":"deliverable","type":"StockLevelStatus"}...', "https://www.hgc.ch/p/#{article}" ] }) do
      get api_hgc_stock_url(article: "100014804"), params: { zip: "1213" }
    end
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal [ "100014804", "1213" ], seen
    assert_equal "deliverable", body["code"]
    assert_equal "ok", body["level"]
    assert_equal "Livrable immédiatement", body["label"]
  end

  test "rejects a malformed article number without calling hgc.ch" do
    post login_url, params: { email: users(:two).email, password: "password123" }
    with_fetch_page(->(*) { flunk "should not fetch" }) do
      get api_hgc_stock_url(article: "abc"), params: { zip: "1213" }
    end
    assert_response :bad_gateway
  end

  test "parse_status reads the first stock status only" do
    html = '"stockLevelStatus":{"code":"orderOnDemandDeliverable"} "stockLevelStatus":{"code":"outOfStock"}'
    assert_equal "orderOnDemandDeliverable", HgcStock.parse_status(html)
  end
end
