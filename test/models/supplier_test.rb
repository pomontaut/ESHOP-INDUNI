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

  test "order_emails combines the main (or canton) address with the optional second one, without duplicates" do
    supplier = Supplier.new(name: "Deux adresses", email: "commandes@f.ch", email_vaud: "vaud@f.ch", email_secondaire: "Compta@f.ch")
    assert_equal "commandes@f.ch, Compta@f.ch", supplier.order_emails
    assert_equal "vaud@f.ch, Compta@f.ch", supplier.order_emails("VAUD")
    assert_equal "commandes@f.ch", Supplier.new(name: "Une adresse", email: "commandes@f.ch").order_emails
    assert_equal "commandes@f.ch", Supplier.new(name: "Doublon", email: "commandes@f.ch", email_secondaire: "COMMANDES@f.ch").order_emails
    assert_nil Supplier.new(name: "Aucune").order_emails
  end

  test "email_secondaire must look like an e-mail address" do
    assert_not Supplier.new(name: "X", email_secondaire: "pas-une-adresse").valid?
    assert Supplier.new(name: "X", email_secondaire: "ok@f.ch").valid?
    assert Supplier.new(name: "X", email_secondaire: "").valid?
  end

  test "an e-mail field accepts several addresses separated by ; , or spaces and normalizes them" do
    supplier = Supplier.create!(name: "HGC multi", email: "commandes_ge@hgc.ch; grand-lancy@hgc.ch;  yannick.mace@hgc.ch , COMMANDES_GE@hgc.ch")
    assert_equal "commandes_ge@hgc.ch, grand-lancy@hgc.ch, yannick.mace@hgc.ch", supplier.email
    assert_equal "commandes_ge@hgc.ch, grand-lancy@hgc.ch, yannick.mace@hgc.ch", supplier.order_emails
    supplier.update!(email_secondaire: "autre@hgc.ch; grand-lancy@hgc.ch")
    assert_equal "commandes_ge@hgc.ch, grand-lancy@hgc.ch, yannick.mace@hgc.ch, autre@hgc.ch", supplier.order_emails
  end

  test "an invalid address inside a multi-address field is rejected and named" do
    supplier = Supplier.new(name: "Mauvais", email: "ok@hgc.ch; pas-une-adresse")
    assert_not supplier.valid?
    assert_match(/pas-une-adresse/, supplier.errors[:email].join)
  end
end
