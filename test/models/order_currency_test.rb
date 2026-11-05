require "test_helper"
class OrderCurrencyTest < ActiveSupport::TestCase
  test "cours serveur" do
    assert Order.chf_rate_for("EUR").between?(0.5, 1.5)
    assert Order.chf_rate_for("USD").between?(0.5, 1.5)
    assert_nil Order.chf_rate_for("GBP")
  end
end
