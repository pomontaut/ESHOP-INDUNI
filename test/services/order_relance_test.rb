require "test_helper"

class OrderRelanceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @supplier = Supplier.create!(name: "Fournisseur Relance", email: "commandes@fournisseur.ch")
    @order = Order.create!(supplier: @supplier, user: users(:one), order_date: Date.current,
                           notes: "Chantier: 12345-Test | Délai: Urgent", status: "sent", approval_status: "approved",
                           email_sent_at: Time.utc(2026, 10, 12, 8, 0), sent_to: "commandes@fournisseur.ch", sent_cc: "copie@induni.ch")
  end

  def at_zurich(*args) = Time.find_zone("Europe/Zurich").local(*args)

  test "working_time? covers weekdays 7h to 18h Zurich time only" do
    assert OrderRelance.working_time?(at_zurich(2026, 10, 13, 7, 0))   # mardi 7h
    assert OrderRelance.working_time?(at_zurich(2026, 10, 13, 17, 59))
    assert_not OrderRelance.working_time?(at_zurich(2026, 10, 13, 6, 59))
    assert_not OrderRelance.working_time?(at_zurich(2026, 10, 13, 18, 0))
    assert_not OrderRelance.working_time?(at_zurich(2026, 10, 17, 10, 0)) # samedi
    assert_not OrderRelance.working_time?(at_zurich(2026, 10, 18, 10, 0)) # dimanche
  end

  test "due only after 24h without reception, once, and never for cancelled or replaced orders" do
    now = Time.utc(2026, 10, 13, 9, 0)
    assert_includes OrderRelance.due(now), @order
    assert_not_includes OrderRelance.due(Time.utc(2026, 10, 12, 20, 0)), @order # < 24h

    @order.update!(reception_confirmed_at: now)
    assert_not_includes OrderRelance.due(now), @order
    @order.update!(reception_confirmed_at: nil, cancelled_at: now)
    assert_not_includes OrderRelance.due(now), @order
    @order.update!(cancelled_at: nil, relance_sent_at: now)
    assert_not_includes OrderRelance.due(now), @order
  end

  test "run_due! sends a single relance inside the working window when enabled" do
    now = at_zurich(2026, 10, 13, 10, 0)
    with_env("RELANCE_AUTO_ENABLED" => "true") do
      assert_emails 1 do
        assert_equal 1, OrderRelance.run_due!(now)
      end
      assert_no_emails { assert_equal 0, OrderRelance.run_due!(now + 1.hour) }
    end
    assert_equal "auto", @order.reload.relance_kind
    assert @order.relance_sent_at.present?
  end

  test "run_due! does nothing when disabled or outside working hours" do
    assert_no_emails { OrderRelance.run_due!(at_zurich(2026, 10, 13, 10, 0)) }
    with_env("RELANCE_AUTO_ENABLED" => "true") do
      assert_no_emails { OrderRelance.run_due!(at_zurich(2026, 10, 17, 10, 0)) }
      assert_no_emails { OrderRelance.run_due!(at_zurich(2026, 10, 13, 19, 0)) }
    end
    assert_nil @order.reload.relance_sent_at
  end

  test "the relance e-mail goes to the supplier with the author in copy and the reception link" do
    mail = OrderMailer.relance(@order)
    assert_equal [ "commandes@fournisseur.ch" ], mail.to
    assert_includes mail.cc, "copie@induni.ch"
    assert_includes mail.cc, users(:one).email
    assert_equal "Relance — Commande N° #{@order.number}", mail.subject
    assert_includes mail.text_part.body.to_s, @order.reception_token
    assert_includes mail.html_part.body.to_s, "12345-Test"
  end

  private

  def with_env(vars)
    old = vars.keys.to_h { |k| [ k, ENV[k] ] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
