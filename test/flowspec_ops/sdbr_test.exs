
defmodule FlowspecOps.SDBRTest do
  use ExUnit.Case, async: true

  alias FlowspecOps.SDBR

  test "default model produces expected results" do
    model = SDBR.new()

    assert SDBR.takt_time(model) == 24.0
    assert SDBR.replenishment_time(model) == 17.0
    assert SDBR.unit_throughput(model) == 4.4
    assert SDBR.daily_throughput(model) == 5280.0
    assert SDBR.annual_throughput(model) == 1_372_800.0
    assert SDBR.annual_operating_expense(model) == 540_000.0
    assert SDBR.target_shipping_buffer_units(model) == 24_480
    assert SDBR.buffer_zone_size(model) == 8160
    assert SDBR.red_zone_threshold(model) == 8160
    assert SDBR.yellow_zone_threshold(model) == 16_320
    assert SDBR.green_zone_threshold(model) == 24_480
    assert SDBR.working_capital_inventory(model) == 51_408.0
    assert SDBR.total_capital_request(model) == 231_408.0
    assert SDBR.annual_net_profit(model) == 832_800.0
    assert Float.round(SDBR.roi_percent(model), 2) == 359.88
    assert SDBR.payback_period_months(model) == 3.33
  end

  test "custom parameters" do
    model = SDBR.new(
      daily_demand: 2000,
      selling_price: 50.0,
      tvc_per_unit: 30.0,
      equipment_capex: 500_000.0
    )

    assert SDBR.takt_time(model) == 14.4
    assert SDBR.unit_throughput(model) == 20.0
    assert SDBR.annual_throughput(model) == 10_400_000.0
  end
end
