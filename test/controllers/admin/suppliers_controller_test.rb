require "test_helper"

class Admin::SuppliersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { email: users(:one).email, password: "password123" }
  end

  test "update stores canton and sector restrictions plus canton-specific emails" do
    supplier = suppliers(:one)

    patch admin_supplier_url(supplier), params: {
      supplier: {
        email: "defaut@example.ch", email_vaud: "vaud@example.ch",
        visible_cantons: [ "VAUD", "FRIBOURG" ],
        visible_sectors: [ "BAT GE" ]
      }
    }

    assert_redirected_to admin_suppliers_path
    supplier.reload
    assert_equal [ "VAUD", "FRIBOURG" ], supplier.visible_cantons
    assert_equal [ "BAT GE" ], supplier.visible_sectors
    assert_equal "vaud@example.ch", supplier.email_vaud
  end

  test "update clears restrictions when 'all cantons'/'all sectors' is checked" do
    supplier = suppliers(:one)
    supplier.update!(visible_cantons: [ "VAUD" ], visible_sectors: [ "BAT GE" ])

    patch admin_supplier_url(supplier), params: {
      supplier: { all_cantons: "1", all_sectors: "1", visible_cantons: [ "VAUD" ], visible_sectors: [ "BAT GE" ] }
    }

    supplier.reload
    assert_equal [], supplier.visible_cantons
    assert_equal [], supplier.visible_sectors
  end

  test "update stores the responsable achat" do
    supplier = suppliers(:one)

    patch admin_supplier_url(supplier), params: { supplier: { responsable_achat: "Emilie Baranski" } }

    assert_redirected_to admin_suppliers_path
    assert_equal "Emilie Baranski", supplier.reload.responsable_achat
  end

  test "requires admin" do
    delete logout_url
    post login_url, params: { email: users(:two).email, password: "password123" }

    get admin_suppliers_url
    assert_redirected_to root_path
  end
end
