require "test_helper"

class SupplierTest < ActiveSupport::TestCase
  test "visible_for_canton? defaults to visible everywhere when no restriction is configured" do
    supplier = Supplier.new
    assert supplier.visible_for_canton?("VAUD")
    assert supplier.visible_for_canton?("GENEVE")
  end

  test "visible_for_canton? restricts to the configured cantons" do
    supplier = Supplier.new(visible_cantons: [ "VAUD", "FRIBOURG" ])
    assert supplier.visible_for_canton?("VAUD")
    assert supplier.visible_for_canton?("FRIBOURG")
    assert_not supplier.visible_for_canton?("GENEVE")
  end

  test "visible_for_sector? defaults to visible everywhere when no restriction is configured" do
    supplier = Supplier.new
    assert supplier.visible_for_sector?("GC")
  end

  test "visible_for_sector? restricts to the configured sectors" do
    supplier = Supplier.new(visible_sectors: [ "BAT GE" ])
    assert supplier.visible_for_sector?("BAT GE")
    assert_not supplier.visible_for_sector?("BAT VD")
  end

  test "email_for_canton falls back to the default email when no override is set" do
    supplier = Supplier.new(email: "defaut@example.ch")
    assert_equal "defaut@example.ch", supplier.email_for_canton("VAUD")
  end

  test "email_for_canton uses the canton-specific override when present" do
    supplier = Supplier.new(email: "defaut@example.ch", email_vaud: "vaud@example.ch")
    assert_equal "vaud@example.ch", supplier.email_for_canton("VAUD")
    assert_equal "defaut@example.ch", supplier.email_for_canton("GENEVE")
  end

  test "email_for_canton returns the default email for a blank canton" do
    supplier = Supplier.new(email: "defaut@example.ch")
    assert_equal "defaut@example.ch", supplier.email_for_canton(nil)
  end
end
