# Investment & S-DBR Factory Model

Simplified Drum-Buffer-Rope & Throughput Accounting (T, I, OE, ROI)

## Unified S-DBR + Lean Execution Model

Lean standardizes execution to compress cycle times, while S-DBR governs system release and capital requirements.

```
  [ Market Demand Rate ] ---> Sets Takt / Market Drum (D)
            |
            v
  [ Material Release ]   ---> Governed by Rope / Order Backlog
            |
            v
  [ Production Cells ]   ---> Cycle Time (Ct) & Touch Time protected by Lean/SMED
            |
            v
  [ Shipping Buffer ]    ---> Protective Buffer (B_total) = Red + Yellow + Green
```

## Core Equations

### 1. Market Takt Time (T_t) / System Cadence

```
T_t = Net Available Operating Time per Day / Average Daily Market Demand Quantity
```

### 2. Total Replenishment Time (RT)

```
RT = L_supplier + L_transit/customs + L_queue + L_production + L_shipping_buffer
```

- **Lean's Role:** SMED (fast mold changes) and 5S/Standardized Work drive L_queue + L_production toward pure touch-time
- **TOC's Role:** RT dictates total working capital tied up in pipeline inventory

### 3. Unified Shipping Buffer Sizing (B_shipping)

```
B_shipping = D × RT × (1 + α_market)
```

- **Green Zone (1/3 B):** Normal operating window. No intervention.
- **Yellow Zone (1/3 B):** Production release zone (reorder triggered).
- **Red Zone (1/3 B):** Expedite zone. High alert to protect due dates.

### 4. Throughput Accounting Capital Efficiency Metrics

- **Throughput (T):** Revenue - Totally Variable Costs (TVC: raw materials, freight, direct sales commission)
- **Investment / Inventory (I):** Total cash tied up in equipment, facility, tooling, raw material stock, and in-flight WIP
- **Operating Expense (OE):** All fixed/semi-variable cash spent to turn I into T (labor, rent, utilities, software)
- **Net Profit (NP):** NP = T - OE
- **Return on Investment (ROI):** ROI = (T - OE) / I

## Dynamic Financial & Operational Sizing Model

Interactive HTML model with sliders for:
- Daily demand, selling price, material cost (TVC)
- Supplier lead time, equipment capital, monthly fixed OE

Outputs: Takt time, RT, buffer size, T, I, OE, NP, ROI

## Investor Pitch Framework

```
+-----------------------------------------------------------------------+
|                       INVESTOR PITCH ARCHITECTURE                     |
+-----------------------------------------------------------------------+
| 1. THE MARKET DRUM        | Proven Demand Rate & Unit Economics       |
| 2. THE BOTTLENECK CAPITAL | Capex Target: Protect/Expand Capacity    |
| 3. WORKING CAPITAL (I)    | Exact Inventory Buffer Sizing ($)         |
| 4. THROUGHPUT VELOCITY    | Capital Payback & ROI ($T - OE) / I       |
+-----------------------------------------------------------------------+
```

### Key Deck Elements

#### 1. The Market Drum (Demand & Unit Velocity)
- Market demand rate: D = 1,200 units/day at $6.50/unit
- TVC = $2.10 (plastic resin + steel shanks)
- Throughput per unit: $4.40

#### 2. The Bottleneck Capital Request (Capex Investment)
- $180,000 in equipment capital for automated demo molding cell and precision shank insertion station
- Every dollar invested at the bottleneck translates 1:1 into increased system-wide Throughput

#### 3. Working Capital & Buffer Protection (I)
- S-DBR Replenishment Time: RT = 17 days
- Working Capital Buffer: $37,000-$51,408 in raw materials and finished goods
- 98.5% due-date delivery rate

#### 4. Throughput Velocity & Payback (ROI)
- Annual Throughput (T): $1,372,800
- Annual Operating Expense (OE): $540,000
- Net Profit: $832,800/year
- Full capital payback in under 3.5 months

## JSON Model Schema

```json
{
  "project_name": "Screwdriver Assembly Line Expansion",
  "unit_economics": {
    "selling_price_usd": 6.50,
    "totally_variable_cost_usd": 2.10,
    "throughput_per_unit_usd": 4.40
  },
  "operational_cadence": {
    "daily_market_demand_units": 1200,
    "takt_time_seconds": 24.0,
    "supplier_replenishment_lead_days": 14,
    "internal_lean_cycle_days": 3,
    "total_replenishment_time_days": 17
  },
  "buffer_management": {
    "target_shipping_buffer_units": 24480,
    "red_zone_units": 8160,
    "yellow_zone_units": 8160,
    "green_zone_units": 8160,
    "required_working_capital_inventory_usd": 51408
  },
  "financial_capital_ask": {
    "equipment_capex_usd": 180000,
    "working_capital_buffer_usd": 51408,
    "total_capital_request_usd": 231408,
    "monthly_operating_expense_usd": 45000,
    "projected_annual_net_profit_usd": 832800,
    "projected_roi_percent": 359.8
  }
}
```

## Relationship to FlowspecOps

This model defines the financial constraints that the factory design must satisfy:
- **Takt time** drives card cycle times and slot counts
- **Buffer sizing** drives storage card slots and movement batch sizes
- **Throughput (T)** is the revenue the factory design must generate
- **Investment (I)** is the capital the factory design must stay within
- **OE** is the operating budget the factory design must operate within

The factory cards (Supplier → Receiving → Storage → Movement → Molding Station) are the physical implementation of this financial model.

## Source Files

- Interactive HTML model: `investment-sdbr-factory-model.html`
- Original source: `/Users/carroll67/Downloads/interactive_visual_im_7daba57d3c35c83e.html`
