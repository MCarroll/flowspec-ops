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

## Rules of Flow / CCPM Foundation (locked 2026-10-11)

The factory is a **blended system** — not a pure project (Gantt) and not a pure
repetitive plant (takt line). It is a complex supply chain managed as one
system, subordinated to a declared CCR, with the crew as the constant and the
stakeholders as the constraint.

### The two lenses

- **CCPM (Critical Chain, Goldratt 1997)** — the *scheduling* layer. Identify
  the critical chain (longest path through dependent tasks *with resource
  contention*), strip task-level safety, aggregate it into a project buffer,
  add feeding buffers, and use buffer management to protect the due date.
  The drum is the constrained resource. Answers: *how do we protect the due
  date.*
- **Rules of Flow (Efrat Goldratt-Ashlag 2022)** — the *flow-management*
  layer. The book Efrat says her father wished to write. Focus shifts off
  buffers and onto the obstacles that clog the flow of work, in multi-project
  / portfolio environments. Answers: *how do we keep many projects flowing
  through one crew without clogging.*

### The 8 Rules of Flow

1. Avoid bad multitasking, control your WIP (WIP = projects handled
   simultaneously; more in the mix = longer lead time).
2. Verify full-kit before you get going (info, approvals, materials in hand
   before starting, or you stall).
3. Triage to work on the right priorities (cut the nice-to-haves).
4. Ensure synchronization between tasks / people / resources (anchor to the
   largest task, align everything to it).
5. Increase the dosage when problems repeat (concentrate, don't spread thin).
6. Avoid unnecessary rework by finding its cause (root cause, not symptom).
7. Standardize when improvising is costly (checklists, standard processes).
8. Abolish local optimum; global optimum matters (energy in the bottleneck).

### The blended model

```
  [ CCPM upstream: crews, work_cells, drum, feeding buffers ]
        |  (Rules of Flow governs: WIP, full-kit, triage, sync)
        v
  [ Shipping Buffer ]  <-- the seam: CCPM buffer mgmt + RoF WIP control
        |
        v
  [ Flow downstream: steady delivery to the market ]
```

- **CCPM upstream** — crew-driven, project-oriented, flexible. This is what
  lets the system pick up new clients fast (reconfigure a crew to a new
  product/site without retooling a flow line).
- **Shipping buffer** — the seam where project work becomes flow. Absorbs the
  variability of crew-driven work and presents a steady stream to the market.
- **Flow downstream** — steady delivery.

### Key convergence: full-kit = step "requires"

Rule 2 (full-kit) is exactly the step-level "requires" mechanism: a step
cannot run until its required inputs are physically in hand — the die, the
design document, the thermal break from another supplier, the 3rd-party
testing firm. The model already designed this; Rules of Flow names it.

### The crew is the constant

The crew is a resource that spans cards, is the drum in crew-driven mode, and
is preserved through the transition to flow. Labor stability is a first-class
constraint (stakeholder principle), not a cost to minimize. When demand
shifts, the flow restructures around the same people; the crew is never the
thing that gets cut.

### The CCR migrates, it is not elevated

The constraint is always present; it changes identity as the system invests.
Phase 1: the crew is the drum. Phase 2 (market proven): a station becomes the
CCR. The tool must let the user re-flag the CCR as the line expands, and the
supplier Gap calc must read against the CCR's rate (min of line commitment
and constraint rate), not each line's own ambition.

## Blended Crew + Slot Model (dialogue capture 2026-10-11, pending fresh-eyes review)

Locking-in session outcome. Open questions at the end — to answer after reviewing
in a new session. Verify with `git log` / this design doc; do not re-derive from
memory.

### Receive / Consume / Deliver with slots

- Every card is a **holding capacity**: it receives, holds item(s) in **slots**,
  steps **consume** from the received slot list, then it **delivers** to fill
  the downstream card's open slots.
- A step can only consume from the card's **received** slots. If the card
  hasn't received it, the step is blocked (full-kit gate).
- Delivery = the upstream side of another card's receive. There is no separate
  delivery table; the graph's links ARE the delivery. A card's delivery is
  expressed as its seq# appearing in the downstream card's slot-table
  "assignment" column.

### Spec + Assignment (dissolves the quick-model vs accurate-model conflict)

Two states on every card, mirrors calijane2's spec/fulfillment but embedded in
the card:

- **Spec state** (fast): card + steps placeable, consumables recorded as
  labels/free-text. No gate enforced.
- **Assigned state** (accurate): consumables pinned to a real source — a part
  (supplier card), a producing line (work_cell), or a tool/doc/service. The
  full-kit gate engages only for assigned items.

Key rule: **only assigned consumption blocks.** Unassigned runs freely, so the
design never locks mid-exploration; accuracy kicks in where it exists.

### Card popup receive manifest (proposed UI)

A table on the card popup. Rows = number of slots. Columns:

  Spec (planned item)  |  Assignment (delivering card seq#)  |  Qty

- Spec-only row = design hypothesis, fast, no gate.
- Spec + Assignment row = resolved, gate on.
- Row count shows slot capacity (a 5-slot card = 5 rows / or grouped, see Q1).

### Full-kit resolves through the graph

A step's consumption can reference a **line**, not just a part: "walls come from
our lamination line." The gate is a graph traversal — resolve each input to an
external supplier or an internal producing line, and confirm the line exists
and flows. Two-level gate: line-level (the producing line must exist) and
step-level (the consumables must be in the card's slots).

### Graph → CAD link

A card's capacity (slots) + position in the flow makes the graph a logical
layout, mappable to a CAD floorplan or a 2D/3D supply-chain map. Same cards /
slots / flow; graph = logic, CAD = geometry.

### Crew = slot-buffer drum (Option A, agreed)

The crew is a resource spanning cards, the drum in crew-driven mode. Each work
cell declares crew-hours of work; the crew's capacity is the constraint. Work
is released only when the kitted step queue is satisfied (the rope). A not-
kitted step blocks release, so the crew is never handed work it can't do —
full-kit becomes a guarantee by construction.

### OPEN QUESTIONS for fresh-eyes review

- **Q1:** Per-slot spec vs grouped rows — for "5 slots × iMod frames", show 5
  identical rows (qty 1 each) or 1 grouped row ("iMod frames — from card 3 —
  qty 5", capacity implied by the row count)? Lean: grouped, to reduce noise
  while the design moves.
   A1: This is table in the popup form for the cards - see table bellow

   | # | Slots | Dim   | Spec            | Assign     | Link(line_seq #) | Qty |
   | 1 | 3     | 50x12 | iMod Frame Base | IM_B01_001 | 1_01             | 1   |
   | 2 | 2     | 10x4  | USG Panels      | USG_34_ctm | 2_01             | 20  |
  
 **Q2:** Where the consuming step references received slots — confirm it is
  the **step** row that names which received slots/items it consumes (step
  table joins slot table), not a column on the slot table.
  - A2: Example workflow - Flooring work_cell, step 1: Place Flooring, consumes
    (#1 iMod Frame Base), (#2 USG Panels) dropdown of what is in the materials table. This will work even if Assign, and Link is empty. 

- **Q3:** Constraint declaration — **explicit** (a flag declaring "this card is
  the CCR") vs **automatic** (tool finds the slowest card). Lean: explicit
  first; automatic needs a full line-rate solver.
  - A3: What if I dont know yet? So im making a hypothesis on where I expect the
  ccr to be? What if the ccr is the market, do we still mark a ccr in the factory? This is what I am not sure about. Can we do a search to see what other TOC experts have said on complex supply chains?
  - **A3 RESOLVED (researched, 2026-10-12):** Yes, model a CCR — but
    **conditionally.** Constraints form a hierarchy checked in order, not a
    pick-one. (From DBR literature + JOM "Evolution of a management philosophy"
    + DBR primer):
      1. **Physical** — a resource (station, crew, transport leg) whose
         capacity < demand.
      2. **Market** — demand < capacity. DBR rule: *"If the CCR works at a rate
         less than the rate demanded by the customer, it is the bottleneck;
         otherwise the external demand rate, the market, is the bottleneck."*
      3. **Policy** — a rule (permitting, interconnection) capping output.
    - If a physical resource is the constraint → flag that card as CCR; its
      rate drives everything.
    - If the market is the constraint → the market demand rate (takt / line
      commitment) is the drum; **no internal card is flagged as CCR.** Marking
      a non-binding resource as CCR would be wrong.
    - **"I don't know yet" = hypothesis mode (not a solver).** The CCR is a
      settable hypothesis; the tool computes the as-if consequence (buffer it
      needs, rate it caps, where the rope releases). The user tests
      hypotheses against observed behavior (where the buffer drains, where
      work queues) and confirms empirically — the TOC way. Explicit flag,
      user-set, changeable; NOT an automatic solver.

- **Q4:** Crew-hours — a property of the **cell** (work content, fixed) with the
  crew's capacity/skill as the variable, vs per-crew skill that changes cell
  time. Lean: property of the cell.
    A4: If I have three cards in a row. And I have staff that works in sequence. Card 1, move to card 2, move to card 3. Card 4 the crew splits in half and on another line have the crew goes to another card. I am just not quite sure how that is shown visually and how it works into the throughput calculations. So maybe we look at this as a kanban situation. If you dont have a card you dont build, likewise the staff moves with a kanban equivilancy.  
    
- **Q5:** Step consumption assignment — **manual** (user specifies "consumes
  from lamination line") vs **semi-auto** (tool suggests candidates). Lean:
  manual; semi-auto is a later nicety.
     A5: See A1.

- **Q6:** PID line / transport buffer window — is the pickup window **relative to
  the supplier's dock ETA** (d1–d2 days after dock hit) or **absolute dates**?
  Lean: relative-to-dock (auto-tracks real ETA).
     A6: So what I am saying with the transport card is that it has a buffer in its modality. What do you recommend here. Remember we have two modes. Design. And then later, if the project is a go, we use the tool as a management system. that is really where the buffer comes into play. In the simulation there is probabilities that could be used. Like a monte carlo simulation. Again need help here.    

- **Q7:** Supplier date anchor — confirm the kickoff date on step 1 is the
  **order date**, and every later step shows its cumulative ETA (order_date +
  running Σ durations), with a "+ STEP" total-bar in the footer. Workstream A
  is a display pass, not new math.
     A7: confirming this is true.  

### Status

**Question status (2026-10-12):**
- **Locked:** Q1 (slot table: `# | Slots | Dim | Spec | Assign | Link(line_seq#) | Qty`), Q2 (step consumption = dropdown of materials table; works with empty Assign/Link), Q3 (CCR conditional + hypothesis mode, researched), Q5 (assignment lives in the slot table), Q7 (supplier date anchor = order date, cumulative ETA, +STEP footer bar).
- **Open design work:** Q4 (crew splitting / kanban visual + throughput calc), Q6 (transport buffer; design mode vs management mode; Monte Carlo / probabilities).

Design dialogue, not built (beyond existing app). Commits: `f08bc25`, `65b8815` (inline step editing), `cebe928` (design capture), `0ea4320` (answers Q1-Q7), current (A3 research). This section supersedes nothing already built; it is the forward design for slot/receive/consume/deliver + crew-as-drum + rules-of-flow layers.
