require "test_helper"

class Admin::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email: "pomontaut@induni.ch", password: "password123", first_name: "Pierre-Olivier", last_name: "Montaut", admin: true)
    @supplier = Supplier.create!(name: "Fournisseur purge")
    OrderLine.delete_all
    Order.delete_all
    3.times { Order.create!(supplier: @supplier, user: @owner, notes: "Chantier: X | Délai souhaité: Y") }
  end

  test "only the permanent owner can open the page" do
    post login_url, params: { email: users(:one).email, password: "password123" } # admin, mais pas propriétaire
    get admin_orders_url
    assert_redirected_to root_path
    delete purge_admin_orders_url, params: { confirmation: "VIDER LES COMMANDES" }
    assert_equal 3, Order.count
  end

  test "export lists every order as CSV" do
    post login_url, params: { email: @owner.email, password: "password123" }
    get export_admin_orders_url
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_equal 4, response.body.lines.size # en-tête + 3
  end

  test "purge requires the exact typed confirmation" do
    post login_url, params: { email: @owner.email, password: "password123" }
    delete purge_admin_orders_url, params: { confirmation: "vider" }
    assert_equal 3, Order.count
  end

  test "purge deletes every order but keeps the numbering going by default" do
    post login_url, params: { email: @owner.email, password: "password123" }
    delete purge_admin_orders_url, params: { confirmation: "VIDER LES COMMANDES" }
    assert_equal 0, Order.count
    assert_equal 0, OrderLine.count
    assert_equal "ESHOP_INDUNI_04", Order.next_number
    assert Supplier.exists?(@supplier.id)
  end

  test "purge can restart the numbering at 01 when asked" do
    post login_url, params: { email: @owner.email, password: "password123" }
    delete purge_admin_orders_url, params: { confirmation: "VIDER LES COMMANDES", reset_numbering: "1" }
    assert_equal 0, Order.count
    assert_equal "ESHOP_INDUNI_01", Order.next_number
  end

  test "purge keeps the listed orders (a real order) and deletes all the others" do
    real = Order.order(:id).first
    real.update!(number: "ESHOP_INDUNI_71")
    post login_url, params: { email: @owner.email, password: "password123" }

    delete purge_admin_orders_url, params: { confirmation: "VIDER LES COMMANDES", keep: "eshop_induni_71" }
    assert_equal [ "ESHOP_INDUNI_71" ], Order.pluck(:number)
    assert_equal "ESHOP_INDUNI_72", Order.next_number
  end

  test "purge deletes nothing when a number to keep does not exist" do
    post login_url, params: { email: @owner.email, password: "password123" }
    delete purge_admin_orders_url, params: { confirmation: "VIDER LES COMMANDES", keep: "ESHOP_INDUNI_999" }
    assert_equal 3, Order.count
  end
end
