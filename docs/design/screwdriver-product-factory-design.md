# Screwdriver Product & Factory Design

## Product: ProForge Screwdriver

### Bill of Materials (BOM)

| Part | SKU | Vendor | Material | Unit Cost | Qty/Unit | Cost/Unit |
|---|---|---|---|---|---|---|
| Handle (PP) | ACME-PP-101 | ACME Plastics Inc. | PP Natural | $2.45/kg | 0.08 kg | $0.196 |
| Shank (Phillips #2) | AST-SHK-PH2-100 | Armstrong Steel Co. | S2 Tool Steel | $0.82 | 1 | $0.82 |
| Packaging | — | — | Cardboard + Blister | $0.15 | 1 | $0.15 |
| **Total TVC** | | | | | | **$1.166** |

**Selling Price:** $6.50/unit
**Throughput/Unit (T):** $6.50 - $1.166 = $5.334

### Product Specs

- Handle: Injection molded PP, ergonomic grip, 120mm length
- Shank: S2 Tool Steel, Phillips #2 tip, 100mm length, 6.35mm hex shank
- Assembly: Ultrasonic weld or crimp
- Packaging: Cardboard backing + blister pack

---

## Factory Design: ProForge Screwdriver Line

### S-DBR Parameters

| Parameter | Value |
|---|---|
| Daily Demand | 1,200 units |
| Takt Time | 24.0 sec/unit |
| Supplier Lead Time | 14 days |
| Internal Lead Time | 3 days |
| Total RT | 17 days |
| Buffer Size | 24,480 units |
| Operating Days/Year | 250 |
| Shift Hours | 8 |

### Factory Flow (Cards)

```
Supplier Card → Receiving → Storage → Molding Station → Assembly Station → QC → Packaging → Shipping Buffer
```

### Card Design

#### 1. Supplier Card
- **Vendor:** ACME Plastics Inc. (resin) + Armstrong Steel Co. (shanks)
- **Parts:** EcoPoly PP Prime, ProForge Phillips #2 Shank
- **Batch:** 1,000 lbs resin + 500 shanks
- **Lead Time:** 14 days
- **Cadence:** Weekly delivery

#### 2. Receiving Card
- **From:** Supplier Card
- **Parts:** Resin + Shanks
- **Batch:** 1,000 lbs + 500 shanks
- **Inspection:** Resin MFI test, shank hardness test
- **Time:** 30 min

#### 3. Storage Card
- **From:** Receiving
- **Parts:** Resin + Shanks
- **Batch:** 1,000 lbs + 500 shanks
- **Slots:** 4 (2 resin, 2 shank)
- **Total:** 2,000 lbs + 1,000 shanks

#### 4. Movement Card
- **From:** Storage
- **Parts:** Resin + Shanks
- **Batch:** 50 lbs resin + 25 shanks
- **Trips/Day:** 20
- **Duration:** 5 min

#### 5. Molding Station (Bottleneck)
- **From:** Movement
- **Part:** PP resin
- **Batch:** 50 lbs (≈625 handles)
- **Slots:** 4
- **Cycle Time:** 24 sec/handle
- **Steps:**
  1. Load mold (5 sec)
  2. Inject PP (10 sec)
  3. Cool (5 sec)
  4. Eject (4 sec)
- **Crew:** 2 people
- **Equipment:** 50-ton injection molder

#### 6. Assembly Station
- **From:** Molding Station + Movement (shanks)
- **Parts:** Handles + Shanks
- **Batch:** 25 units
- **Slots:** 2
- **Cycle Time:** 24 sec/unit
- **Steps:**
  1. Load handle (4 sec)
  2. Insert shank (6 sec)
  3. Ultrasonic weld (8 sec)
  4. Eject (6 sec)
- **Crew:** 1 person
- **Equipment:** Ultrasonic welder

#### 7. Quality Control
- **From:** Assembly Station
- **Batch:** 25 units
- **Inspection:** Torque test, visual inspection
- **Time:** 10 sec/unit
- **Rejection Rate:** 0.5%

#### 8. Packaging
- **From:** QC
- **Batch:** 25 units
- **Time:** 8 sec/unit
- **Output:** Cardboard + blister pack

#### 9. Shipping Buffer
- **From:** Packaging
- **Buffer Size:** 24,480 units
- **Red Zone:** 8,160 units
- **Yellow Zone:** 8,160 units
- **Green Zone:** 8,160 units

---

## Financial Model

### Throughput Accounting

| Metric | Value |
|---|---|
| Selling Price | $6.50/unit |
| TVC | $1.166/unit |
| Throughput (T)/unit | $5.334 |
| Daily Demand | 1,200 units |
| Annual T | $5.334 × 1,200 × 250 = $1,600,200 |
| Annual OE | $540,000 |
| Net Profit | $1,060,200 |
| Equipment CapEx | $180,000 |
| Working Capital | $51,408 |
| Total Investment (I) | $231,408 |
| ROI | 458.3% |
| Payback Period | 2.6 months |

### Capital Request

| Item | Amount |
|---|---|
| Injection Molder (50-ton) | $80,000 |
| Ultrasonic Welder | $25,000 |
| Assembly Fixtures | $15,000 |
| QC Equipment | $10,000 |
| Material Handling | $20,000 |
| Facility Setup | $30,000 |
| **Equipment CapEx** | **$180,000** |
| Working Capital Buffer | $51,408 |
| **Total Request** | **$231,408** |

---

## Investor Pitch

### 1. The Market Drum
"Market demand is 1,200 screwdrivers/day at $6.50/unit. With TVC of $1.166 (resin + steel shank + packaging), every unit generates $5.334 of pure Throughput."

### 2. The Bottleneck Capital Request
"We are requesting $180,000 in equipment capital for the automated injection molding cell and ultrasonic assembly station. These are the system constraints — every dollar invested here translates 1:1 into increased system-wide Throughput."

### 3. Working Capital & Buffer Protection
"By leveraging S-DBR Replenishment Time (RT = 17 days) and Lean execution, we require a precise Working Capital Buffer of $51,408 in raw materials and finished goods to maintain 98.5% due-date delivery."

### 4. Throughput Velocity & Payback
"Annual Throughput reaches $1,600,200. Subtracting annual OE of $540,000, the plant yields a Net Profit of $1,060,200/year, achieving full capital payback in under 3 months."

---

## Implementation Plan

### Phase 1: Equipment Procurement (Weeks 1-4)
- Order injection molder, ultrasonic welder, fixtures
- Facility setup and utilities

### Phase 2: Installation & Debug (Weeks 5-8)
- Install equipment
- Debug molding process
- Debug assembly process

### Phase 3: Pilot Run (Weeks 9-10)
- Run at 50% capacity (600 units/day)
- Validate quality and cycle times

### Phase 4: Full Production (Week 11+)
- Ramp to 100% (1,200 units/day)
- Monitor buffer levels and due-date performance

---

## Relationship to FlowspecOps

This design is implemented in FlowspecOps as Factory 2:
- Cards: Supplier → Receiving → Storage → Movement → Molding Station → Assembly → QC → Packaging → Shipping Buffer
- Each card has INPUT section (Vendor, Part, Batch)
- Links define material flow
- S-DBR parameters drive card timing and buffer sizing
