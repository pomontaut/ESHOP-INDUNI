require "test_helper"

class Admin::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @supplier = Supplier.create!(name: "Fournisseur Export")
    @product = Product.create!(supplier: @supplier, reference: "EXP-1", name: "Article export", unit_price: 10)
  end

  test "price history only records real price changes" do
    assert_equal [ 10 ], @product.price_changes.pluck(:price).map(&:to_i)

    @product.update!(name: "Renommé", unit_price: 10)
    assert_equal 1, @product.price_changes.count

    @product.update!(unit_price: 12.5)
    assert_equal [ 10, 12.5 ], @product.price_changes.order(:id).pluck(:price).map(&:to_f)
  end

  test "export downloads an xlsx for admins" do
    @product.update!(unit_price: 11)
    post login_url, params: { email: users(:one).email, password: "password123" }

    get export_admin_products_url(format: :xlsx), params: { supplier_id: @supplier.id }

    assert_response :success
    assert_equal Admin::ProductsController::XLSX_TYPE, response.media_type
    assert response.body.start_with?("PK"), "an .xlsx is a zip archive"
    sheets = Zip::InputStream.open(StringIO.new(response.body)) { |zip| names = []; while (e = zip.get_next_entry); names << e.name; end; names }
    assert_includes sheets, "xl/worksheets/sheet2.xml"
  end

  test "export never contains confidential prices" do
    @supplier.update!(confidential_pricing: true)
    post login_url, params: { email: users(:one).email, password: "password123" }

    get export_admin_products_url(format: :xlsx), params: { supplier_id: @supplier.id }

    strings = Zip::InputStream.open(StringIO.new(response.body)) do |zip|
      content = +""
      while (e = zip.get_next_entry)
        content << zip.read if e.name.start_with?("xl/worksheets/") || e.name == "xl/sharedStrings.xml"
      end
      content
    end
    assert_includes strings, "Confidentiel"
    assert_match(/<c r="G2"[^>]*t="s"/, strings, "price cell must be the text 'Confidentiel', not a number")
    assert_equal 1, strings.scan('<row r="2"').size, "no price history row may be exported for a confidential supplier"
  end

  test "export is refused to non-admins" do
    post login_url, params: { email: users(:two).email, password: "password123" }
    get export_admin_products_url(format: :xlsx)
    assert_redirected_to root_path
  end

  test "catalog:seed price history ignores unchanged prices" do
    Rails.application.load_tasks unless Rake::Task.task_defined?("catalog:seed")
    Rake::Task["catalog:seed"].reenable
    Rake::Task["catalog:seed"].invoke
    count = ProductPriceChange.count
    assert count.positive?

    Rake::Task["catalog:seed"].reenable
    Rake::Task["catalog:seed"].invoke
    assert_equal count, ProductPriceChange.count
  end
end
