# Data Center Factory S-DBR Model (DC-flavored)

Sibling to `investment-sdbr-factory-model.md`. Same TOC skeleton, re-mapped to a
data-center / skid buildout. The drum is the GPU+power+permit path (a
machine/resource CCR), NOT the crew. The crew is the constant.

## Mapping from the manufacturing model

| Screwdriver model        | Data center model                          |
|--------------------------|--------------------------------------------|
| Daily demand (units)     | Committed tenant kW / racks (D)            |
| Selling price / TVC      | $/rack-month (or $/kW) minus power+GPU cost|
| Supplier lead (14d)      | GPU/B300 lead + frame + power + permit     |
| Internal cycle (3d)      | Skid cycle time (your shop)                |
| Shipping buffer (units)  | Shippable-rack window protecting go-live   |
| 98.5% due-date rate      | Tenant power-on window hit rate            |
| Equipment capex          | Skids, frames, coolant loop, facility      |
| Crew as drum (phase 1)   | Crew CONSTANT; CCR migrates to machine     |

## The survival constraint (why this model exists)

US manufacturing lost to the offshore race because labor cost was treated as a
variable to minimize, and the answer was cheap/abused labor overseas. That
loses BOTH morally and operationally: wage arbitrage is a permanently eroding
moat. This model competes on the two things decent labor wins at:

1. Throughput velocity — compress RT so capital turns faster (S-DBR buffer +
   Rules of Flow keep WIP low and full-kit rigorous).
2. Due-date reliability — win on "we hit your go-live window," which offshore /
   speculative players cannot promise.

So `fair_labor_floor` is a HARD constraint, not a soft goal. The solver may
never tune the model by cutting crew below the floor. If the model can't make
money honoring decent labor, the answer is raise throughput or change the
offer — never abuse labor to close the gap. That is the delicate line, made
structural instead of sentimental.

## JSON Schema (v1)

```json
{
  "schema": "dc-sdbr/v1",
  "project_name": "Micro Data Center Skid Buildout",
  "labor_floor": {
    "fair_labor_floor": "hard_constraint",
    "crew_is_constant": true,
    "min_wage_floor_usd_hour": 28,
    "crew_preserved_on_demand_shift": true
  },
  "unit_economics": {
    "drum_unit": "rack",
    "revenue_per_rack_month_usd": 18000,
    "totally_variable_cost_usd_per_rack_month": 9200,
    "throughput_per_rack_month_usd": 8800
  },
  "operational_cadence": {
    "committed_rack_demand_month": 140,
    "takt_time_days_per_rack": 2.1,
    "ccr": {
      "name": "gpu_b300_supply_power_permit",
      "kind": "machine/resource_not_crew",
      "phase": 1
    },
    "supplier_replenishment": {
      "gpu_lead_days": 90,
      "frame_lead_days": 28,
      "power_permit_lead_days": 120
    },
    "internal_skid_cycle_days": 14,
    "total_replenishment_time_days": 120
  },
  "buffer_management": {
    "target_shipping_window_racks": 8,
    "red_zone_racks": 3,
    "yellow_zone_racks": 3,
    "green_zone_racks": 2,
    "protection": "tenant_power_on_window",
    "target_window_hit_rate": 0.985
  },
  "financial_capital_ask": {
    "skid_equipment_capex_usd": 2400000,
    "working_capital_buffer_usd": 610000,
    "total_capital_request_usd": 3010000,
    "monthly_operating_expense_usd": 210000,
    "projected_annual_net_profit_usd": 9100000,
    "projected_roi_percent": 302.0
  }
}
```

## Where the philosophy is enforced, not just declared

- `ccr` is machine/resource — the model never needs to game crew cost to move
  the bottleneck, because the bottleneck isn't labor to begin with.
- `crew_preserved_on_demand_shift: true` forces the flow to restructure around
  the same people when demand moves (their own Rules-of-Flow principle), so the
  solver can't "save" money by shedding the crew.
- The `buffer` protects a committed tenant window — the argument that wins a
  tribal/coop/county meeting. Velocity + reliability, not wage arbitrage.
- The **migrating CCR note** from the original model applies here verbatim:
  phase 2 (market proven) the CCR may shift to a station; the flag must
  re-point. Do not let the model claim a crew CCR when the real drum is a
  90-day GPU lead.

## Open questions (fresh-eyes)

- **D1:** Is the drum a *contracted* kW number from a real tenant, or a
  speculative "market" rate? Model refuses to run a drum without a committed
  kW+date input — this is the anti-speculator gate by construction.
- **D2:** Fair-labor floor as absolute wage vs. a relative "does not compete on
  wage arbitrage" ratio? Absolute is cleaner to enforce; relative survives
  inflation better. Lean: absolute floor now, revisit.
- **D3:** Where does siting/permitting cost live — as part of `power_permit_lead`
  (time) or as a capex line (tribal/county fees)? Lean: both, but the buffer
  only absorbs TIME, capex absorbs cost.
