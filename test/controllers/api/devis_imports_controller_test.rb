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

  test "surfaces the AI-suggested category on an unmatched reference" do
    fake_lines = [
      {
        reference: "UNKNOWN-99", designation: "Article inconnu", quantity: 3, unit: "PCE", unit_price: 4.2,
        is_variant: false, suggested_famille: "Ciments & Bétons", suggested_sous_famille: "Béton"
      }
    ]

    with_stubbed_extraction(fake_lines) do
      post api_devis_imports_url, params: { supplier: "HGC", file: fixture_file_upload(".keep", "application/pdf") }
    end

    item = JSON.parse(response.body)["items"].first
    assert_equal "Ciments & Bétons", item["suggestedFamille"]
    assert_equal "Béton", item["suggestedSousFamille"]
  end

  test "confirm_products creates a manually-added product with the confirmed category" do
    post confirm_products_api_devis_imports_url, params: {
      supplier: "HGC",
      products: [
        { reference: "NEW-REF-1", designation: "Article du devis", prix: 9.9, unite: "PCE", famille: "Ciments & Bétons", sousFamille: "Béton" }
      ]
    }

    assert_response :success
    assert_equal [ "NEW-REF-1" ], JSON.parse(response.body)["added"]

    product = Product.find_by(supplier: @supplier, reference: "NEW-REF-1")
    assert product
    assert product.manually_added?
    assert_equal "Ciments & Bétons", product.famille
    assert_equal "Béton", product.sous_famille
    assert_equal 9.9, product.unit_price.to_f
  end

  test "confirm_products never overwrites an existing non-manually-added product" do
    post confirm_products_api_devis_imports_url, params: {
      supplier: "HGC",
      products: [ { reference: @product.reference, designation: "Prix bidon", prix: 0.01, unite: "PCE", famille: "Bidon" } ]
    }

    assert_response :success
    assert_equal [], JSON.parse(response.body)["added"]
    @product.reload
    assert_equal "Tuyau PVC test", @product.name
    assert_equal 12.5, @product.unit_price.to_f
    assert_not @product.manually_added?
  end

  test "builds a generic line for a surcharge (e.g. fuel surcharge)" do
    with_stubbed_extraction([], surcharges: [ { label: "Supplément carburant", amount: 5.04 } ]) do
      post api_devis_imports_url, params: { supplier: "HGC", file: fixture_file_upload(".keep", "application/pdf") }
    end

    items = JSON.parse(response.body)["items"]
    assert_equal 1, items.length
    surcharge = items.first
    assert surcharge["generic"]
    assert_not surcharge["matched"]
    assert_equal "Supplément carburant", surcharge["designation"]
    assert_nil surcharge["prix"]
    assert_equal 5.04, surcharge["devisPrix"]
    assert_equal 1.0, surcharge["qty"]
  end

  test "rejects an unknown supplier" do
    post api_devis_imports_url, params: { supplier: "Fournisseur Inconnu", file: fixture_file_upload(".keep", "application/pdf") }
    assert_response :unprocessable_entity
  end

  test "rejects a user without the import-quote permission" do
    delete logout_url
    post login_url, params: { email: users(:two).email, password: "password123" }

    post api_devis_imports_url, params: { supplier: "HGC", file: fixture_file_upload(".keep", "application/pdf") }
    assert_response :forbidden
  end

  test "allows a user granted the import-quote permission" do
    users(:two).update!(can_import_quote: true)
    delete logout_url
    post login_url, params: { email: users(:two).email, password: "password123" }

    fake_lines = [
      { reference: "REF-123", designation: "Tuyau PVC (devis)", quantity: 1, unit: "M", unit_price: 12.5, is_variant: false }
    ]
    with_stubbed_extraction(fake_lines) do
      post api_devis_imports_url, params: { supplier: "HGC", file: fixture_file_upload(".keep", "application/pdf") }
    end
    assert_response :success
  end

  private

  # DevisExtractorService#extract normally calls the Anthropic API. Swap the
  # class's `.new` for the duration of the block so tests don't hit the network.
  def with_stubbed_extraction(lines, surcharges: [])
    fake_service = Object.new
    fake_service.define_singleton_method(:extract) { { items: lines.map(&:dup), surcharges: surcharges.map(&:dup) } }
    original_new = DevisExtractorService.method(:new)
    DevisExtractorService.define_singleton_method(:new) { |*_args| fake_service }
    yield
  ensure
    DevisExtractorService.define_singleton_method(:new, original_new)
  end
end
