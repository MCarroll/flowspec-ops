defmodule FlowspecOps.SDBR do
  @moduledoc """
  Simplified Drum-Buffer-Rope & Throughput Accounting calculation engine.

  Ported from the Ruby SDBRExecutionModel reference implementation.
  """

  defstruct [
    :daily_demand,
    :selling_price,
    :tvc_per_unit,
    :supplier_lead_days,
    :internal_cycle_days,
    :equipment_capex,
    :monthly_oe,
    :operating_seconds_per_day,
    :operating_days_per_year,
    :market_variability_factor,
    :cycle_time
  ]

  @type t :: %__MODULE__{
    daily_demand: float(),
    selling_price: float(),
    tvc_per_unit: float(),
    supplier_lead_days: float(),
    internal_cycle_days: float(),
    equipment_capex: float(),
    monthly_oe: float(),
    operating_seconds_per_day: float(),
    operating_days_per_year: integer(),
    market_variability_factor: float()
  }

  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      daily_demand: Keyword.get(opts, :daily_demand, 1200),
      selling_price: Keyword.get(opts, :selling_price, 6.50),
      tvc_per_unit: Keyword.get(opts, :tvc_per_unit, 2.10),
      supplier_lead_days: Keyword.get(opts, :supplier_lead_days, 14),
      internal_cycle_days: Keyword.get(opts, :internal_cycle_days, 3),
      equipment_capex: Keyword.get(opts, :equipment_capex, 180_000.0),
      monthly_oe: Keyword.get(opts, :monthly_oe, 45_000.0),
      operating_seconds_per_day: Keyword.get(opts, :operating_seconds_per_day, 28_800),
      operating_days_per_year: Keyword.get(opts, :operating_days_per_year, 260),
      market_variability_factor: Keyword.get(opts, :market_variability_factor, 0.20),
      cycle_time: Keyword.get(opts, :cycle_time, nil)
    }
  end

  # --- 1. Operational Cadence ---

  @spec takt_time(t()) :: float()
  def takt_time(%__MODULE__{} = m) do
    m.operating_seconds_per_day / m.daily_demand
  end

  @spec replenishment_time(t()) :: float()
  def replenishment_time(%__MODULE__{} = m) do
    m.supplier_lead_days + m.internal_cycle_days
  end

  # --- 2. Throughput Accounting (T, I, OE) ---

  @spec unit_throughput(t()) :: float()
  def unit_throughput(%__MODULE__{} = m) do
    m.selling_price - m.tvc_per_unit
  end

  @spec daily_throughput(t()) :: float()
  def daily_throughput(%__MODULE__{} = m) do
    m.daily_demand * unit_throughput(m)
  end

  @spec annual_throughput(t()) :: float()
  def annual_throughput(%__MODULE__{} = m) do
    daily_throughput(m) * m.operating_days_per_year
  end

  @spec annual_operating_expense(t()) :: float()
  def annual_operating_expense(%__MODULE__{} = m) do
    m.monthly_oe * 12.0
  end

  # --- 3. Buffer Sizing & Working Capital ---

  @spec target_shipping_buffer_units(t()) :: integer()
  def target_shipping_buffer_units(%__MODULE__{} = m) do
    (m.daily_demand * replenishment_time(m) * (1.0 + m.market_variability_factor))
    |> round()
  end

  @spec buffer_zone_size(t()) :: integer()
  def buffer_zone_size(%__MODULE__{} = m) do
    (target_shipping_buffer_units(m) / 3.0)
    |> round()
  end

  @spec red_zone_threshold(t()) :: integer()
  def red_zone_threshold(%__MODULE__{} = m), do: buffer_zone_size(m)

  @spec yellow_zone_threshold(t()) :: integer()
  def yellow_zone_threshold(%__MODULE__{} = m), do: buffer_zone_size(m) * 2

  @spec green_zone_threshold(t()) :: integer()
  def green_zone_threshold(%__MODULE__{} = m), do: target_shipping_buffer_units(m)

  @spec working_capital_inventory(t()) :: float()
  def working_capital_inventory(%__MODULE__{} = m) do
    target_shipping_buffer_units(m) * m.tvc_per_unit
  end

  # --- 4. Financial Capital Ask & Returns ---

  @spec total_capital_request(t()) :: float()
  def total_capital_request(%__MODULE__{} = m) do
    m.equipment_capex + working_capital_inventory(m)
  end

  @spec annual_net_profit(t()) :: float()
  def annual_net_profit(%__MODULE__{} = m) do
    annual_throughput(m) - annual_operating_expense(m)
  end

  @spec roi_percent(t()) :: float()
  def roi_percent(%__MODULE__{} = m) do
    (annual_net_profit(m) / total_capital_request(m)) * 100.0
  end

  @spec payback_period_months(t()) :: float()
  def payback_period_months(%__MODULE__{} = m) do
    (total_capital_request(m) / (annual_net_profit(m) / 12.0))
    |> Float.round(2)
  end

  # --- Export Schema Payload ---

  @spec to_h(t()) :: map()
  def to_h(%__MODULE__{} = m) do
    %{
      project_name: "Screwdriver Assembly Line Expansion",
      unit_economics: %{
        selling_price_usd: Float.round(m.selling_price, 2),
        totally_variable_cost_usd: Float.round(m.tvc_per_unit, 2),
        throughput_per_unit_usd: Float.round(unit_throughput(m), 2)
      },
      operational_cadence: %{
        daily_market_demand_units: round(m.daily_demand),
        takt_time_seconds: Float.round(takt_time(m), 2),
        supplier_replenishment_lead_days: round(m.supplier_lead_days),
        internal_lean_cycle_days: round(m.internal_cycle_days),
        total_replenishment_time_days: round(replenishment_time(m))
      },
      buffer_management: %{
        target_shipping_buffer_units: target_shipping_buffer_units(m),
        red_zone_units: red_zone_threshold(m),
        yellow_zone_units: yellow_zone_threshold(m),
        green_zone_units: green_zone_threshold(m),
        required_working_capital_inventory_usd: Float.round(working_capital_inventory(m), 2)
      },
      financial_capital_ask: %{
        equipment_capex_usd: Float.round(m.equipment_capex, 2),
        working_capital_buffer_usd: Float.round(working_capital_inventory(m), 2),
        total_capital_request_usd: Float.round(total_capital_request(m), 2),
        monthly_operating_expense_usd: Float.round(m.monthly_oe, 2),
        projected_annual_net_profit_usd: Float.round(annual_net_profit(m), 2),
        projected_roi_percent: Float.round(roi_percent(m), 2),
        payback_period_months: payback_period_months(m)
      }
    }
  end

  @spec to_json(t()) :: String.t()
  def to_json(%__MODULE__{} = m) do
    m
    |> to_h()
    |> Jason.encode!(pretty: true)
  end
end
