require "test_helper"

class Api::ReceptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { email: users(:one).email, password: "password123" }
    @supplier = Supplier.create!(name: "Fournisseur reception", email: "commandes@fournisseur.ch")
    @product = Product.create!(supplier: @supplier, reference: "REC-1", name: "Tuyau test", unit_price: 10, unite: "pce")
    @order = Order.create!(supplier: @supplier, order_date: Date.current, notes: "Chantier: Test | Délai souhaité: 01.12.2026", user: users(:one))
    @line = @order.order_lines.create!(product: @product, quantity: 10, unit_price: 10)
  end

  test "module réservé à l'environnement test" do
    get api_reception_orders_url
    assert_response :forbidden
  end

  test "refusé dans les vues Contremaître et Conducteur de travaux de l'environnement test" do
    [ "Contremaître", "Conducteur de travaux" ].each do |profile|
      post api_test_profile_url, params: { profile: profile }
      get api_reception_orders_url
      assert_response :forbidden
    end
  end

  test "commande, appel de livraison, réception partielle puis solde avec scan de BL" do
    post api_test_profile_url, params: { profile: "Développement" }
    get api_reception_orders_url
    assert_response :success
    row = JSON.parse(response.body).find { |o| o["id"] == @order.id }
    assert_equal "ordered", row["status"]
    assert_equal "C1", row["type"]

    post api_reception_create_call_url(@order), params: { planned_on: "2026-11-02", planned_time: "07:30", lines: [ { id: @line.id, quantity: 10 } ] }
    assert_response :created
    detail = JSON.parse(response.body)
    assert_equal "planned", detail["status"]
    assert_equal 10.0, detail["lines"].first["planned"]
    call_id = detail["calls"].first["id"]

    scan = Rack::Test::UploadedFile.new(StringIO.new("%PDF-1.4 test"), "application/pdf", original_filename: "bl.pdf")
    post api_reception_create_reception_url(@order), params: { delivery_call_id: call_id, bl_number: "BL-77", status: "reserves",
      lines: [ { id: @line.id, quantity: 6, accepted: 5 } ], scans: [ scan ] }
    assert_response :created
    detail = JSON.parse(response.body)
    assert_equal "partial", detail["status"]
    line = detail["lines"].first
    assert_equal [ 6.0, 5.0, 5.0 ], [ line["delivered"], line["accepted"], line["remaining"] ]
    scan_url = detail["receptionList"].first["scans"].first["url"]
    get scan_url
    assert_response :success
    assert_equal "application/pdf", response.media_type

    post api_reception_create_reception_url(@order), params: { lines: [ { id: @line.id, quantity: 5 } ] }
    assert_response :created
    assert_equal "accepted", JSON.parse(response.body)["status"]
    assert_equal 0, @order.delivery_calls.where(status: "planned").count

    patch api_reception_update_order_url(@order), params: { invoiced: true }
    assert_equal "invoiced", JSON.parse(response.body)["status"]
  end

  test "prestation C5 : réception par avancement" do
    post api_test_profile_url, params: { profile: "Développement" }
    patch api_reception_update_order_url(@order), params: { reception_type: "C5" }
    post api_reception_create_reception_url(@order), params: { progress_percent: 40 }
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal 40.0, body["acceptedPercent"]
    assert_equal "partial", body["status"]
  end

  test "lignes envoyées en champs indexés (formulaire multipart du navigateur)" do
    post api_test_profile_url, params: { profile: "Développement" }
    post api_reception_create_reception_url(@order), params: { "lines" => { "0" => { "id" => @line.id, "quantity" => "4", "accepted" => "4" } } }
    assert_response :created
    assert_equal 4.0, JSON.parse(response.body)["lines"].first["accepted"]
  end

  test "un fichier non accepté est refusé" do
    post api_test_profile_url, params: { profile: "Développement" }
    bad = Rack::Test::UploadedFile.new(StringIO.new("MZ"), "application/x-msdownload", original_filename: "x.exe")
    post api_reception_create_reception_url(@order), params: { lines: [ { id: @line.id, quantity: 1 } ], scans: [ bad ] }
    assert_response :unprocessable_entity
    assert_equal 0, Reception.count
  end
end
