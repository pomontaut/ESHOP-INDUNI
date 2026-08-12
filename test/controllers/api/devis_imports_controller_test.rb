require "test_helper"

class Api::DevisImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { email: users(:one).email, password: "password123" }
    @supplier = Supplier.create!(name: "HGC")
    @product = Product.create!(
      supplier: @supplier,
      reference: "REF-123",
      name: "Tuyau PVC test",
      unit_price: 12.50,
      unite: "M",
      famille: "Test"
    )
  end

  test "matches an existing product and keeps the e-shop price" do
    fake_lines = [
      { reference: "ref-123", designation: "Tuyau PVC (devis)", quantity: 5, unit: "M", unit_price: 15.0, is_variant: false }
    ]

    with_stubbed_extraction(fake_lines) do
      post api_devis_imports_url, params: { supplier: "HGC", file: fixture_file_upload(".keep", "application/pdf") }
    end

    assert_response :success
    items = JSON.parse(response.body)["items"]
    assert_equal 1, items.length
    item = items.first
    assert item["matched"]
    assert_not item["generic"]
    assert_equal "REF-123", item["article"]
    assert_equal 12.5, item["prix"]
    assert_equal 5.0, item["qty"]
    assert_not item["cheaperAtSupplier"]
  end

  test "flags when the devis price is cheaper than the e-shop price" do
    fake_lines = [
      { reference: "REF-123", designation: "Tuyau PVC (devis)", quantity: 2, unit: "M", unit_price: 8.0, is_variant: false }
    ]

    with_stubbed_extraction(fake_lines) do
      post api_devis_imports_url, params: { supplier: "HGC", file: fixture_file_upload(".keep", "application/pdf") }
    end

    item = JSON.parse(response.body)["items"].first
    assert item["cheaperAtSupplier"]
    assert_equal 12.5, item["prix"], "must still use the e-shop price, not the devis price"
  end

  test "builds a generic article for an unmatched reference" do
    fake_lines = [
      { reference: "UNKNOWN-99", designation: "Article inconnu", quantity: 3, unit: "PCE", unit_price: 4.2, is_variant: false }
    ]

    with_stubbed_extraction(fake_lines) do
      post api_devis_imports_url, params: { supplier: "HGC", file: fixture_file_upload(".keep", "application/pdf") }
    end

    item = JSON.parse(response.body)["items"].first
    assert_not item["matched"]
    assert item["generic"]
    assert_equal "UNKNOWN-99", item["article"]
    assert_equal "Article inconnu", item["designation"]
    assert_equal 3.0, item["qty"]
    assert_nil item["prix"]
  end

  test "rejects an unknown supplier" do
    post api_devis_imports_url, params: { supplier: "Fournisseur Inconnu", file: fixture_file_upload(".keep", "application/pdf") }
    assert_response :unprocessable_entity
  end

  private

  # DevisExtractorService#extract normally calls the Anthropic API. Swap the
  # class's `.new` for the duration of the block so tests don't hit the network.
  def with_stubbed_extraction(lines)
    fake_service = Object.new
    fake_service.define_singleton_method(:extract) { lines.map(&:dup) }
    original_new = DevisExtractorService.method(:new)
    DevisExtractorService.define_singleton_method(:new) { |*_args| fake_service }
    yield
  ensure
    DevisExtractorService.define_singleton_method(:new, original_new)
  end
end
