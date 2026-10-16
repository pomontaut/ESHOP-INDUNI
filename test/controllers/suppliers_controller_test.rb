require "test_helper"

class SuppliersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { email: users(:one).email, password: "password123" }
    @supplier = suppliers(:one)
  end

  test "should get index" do
    get suppliers_url
    assert_response :success
  end

  test "should get show" do
    get supplier_url(@supplier)
    assert_response :success
  end

  test "should get new" do
    get new_supplier_url
    assert_response :success
  end

  test "should get edit" do
    get edit_supplier_url(@supplier)
    assert_response :success
  end

  test "update accepts several order addresses separated by semicolons" do
    supplier = Supplier.create!(name: "HGC page historique", email: "a@hgc.ch")
    patch supplier_url(supplier), params: { supplier: { email: "commandes_ge@hgc.ch; grand-lancy@hgc.ch; yannick.mace@hgc.ch" } }
    assert_redirected_to supplier_url(supplier)
    assert_equal "commandes_ge@hgc.ch, grand-lancy@hgc.ch, yannick.mace@hgc.ch", supplier.reload.email
  end
end
