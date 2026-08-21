require "test_helper"

class DieselPriceTest < ActiveSupport::TestCase
  test "surcharge_pct matches the published ASTAG scale exactly at its reference points" do
    { 1.235 => -5.0, 1.325 => -4.0, 1.415 => -3.0, 1.505 => -2.0, 1.595 => -1.0,
      1.64 => 0.0, 1.685 => 1.0, 1.775 => 2.0, 1.865 => 3.0, 1.955 => 4.0,
      2.045 => 5.0, 2.135 => 6.0, 2.225 => 7.0, 2.315 => 8.0, 2.405 => 9.0 }.each do |chf, pct|
      d = DieselPrice.new(price: chf)
      assert_in_delta pct, d.surcharge_pct, 0.001, "price #{chf} should be #{pct}%"
    end
  end

  test "surcharge_pct interpolates between reference points, not a flat percentage of the base" do
    # 2.19 sits between the 6% (2.135) and 7% (2.225) rungs — a naive
    # (price - base) / base * 100 would give ~33.5%, which is wrong: the
    # ASTAG scale's first step (0% to ±1%) is only half the size of every
    # later step, so it can't be reproduced by a single linear formula.
    d = DieselPrice.new(price: 2.19)
    assert_in_delta 6.61, d.surcharge_pct, 0.05
  end

  test "surcharge_pct extrapolates beyond the published scale using the outer segment's slope" do
    above = DieselPrice.new(price: 3.0)
    below = DieselPrice.new(price: 1.0)
    assert_in_delta 15.61, above.surcharge_pct, 0.05
    assert_in_delta(-7.61, below.surcharge_pct, 0.05)
  end
end
