---
schema_version: 2
factory:
  slug: va-transitional-housing
  name: VA Transitional Housing
  client:
    slug: imod
    name: iMod Systems
    owner: Reed Walker
  status: draft
  notes: >
    Wave 1 — Frame Line story. Node kinds upgraded from station|buffer to
    work_cell|queue|supplier|transport. Lines, links, SKU routing, slots,
    and inspection gates now modeled. Cycle times and PFEP levels are TBD.

skus:
  - code: SKU-A
    name: Modular Unit — Standard
  - code: SKU-B
    name: Modular Unit — ADA

lines:
  - id: frame-line
    name: Frame Line
    position: 1

nodes:
  - id: kitchen-podular
    kind: supplier
    line: frame-line
    name: Frame Mfg
    position: 1
    inspection_point: true        # outgoing gate at supplier
    location_note: Livermore, CA
    lead_time_days: 14
    supply_cadence: weekly

  - id: transport-lv-vallejo
    kind: transport
    line: frame-line
    name: Transport
    position: 2
    from_location: Livermore, CA
    to_location: Vallejo, CA
    transport_duration_minutes: 90

  - id: receiving
    kind: work_cell
    line: frame-line
    name: Receiving
    position: 3
    inspection_point: true        # incoming receive gate
    slots: 1
    steps:
      - name: Receive and inspect frame
        estimated_minutes: null   # TBD

  - id: eps-lot-one
    kind: queue
    queue_role: storage_lot
    line: frame-line
    name: EPS Lot One
    position: 4
    slots: 10
    note: >
      10-slot storage lot. Frames hold here when Flooring bay is occupied.

  - id: flooring
    kind: work_cell
    line: frame-line
    name: Flooring
    position: 5
    slots: 3
    steps:
      - name: Install flooring panels
        estimated_minutes: null   # TBD
      - name: Inspect and sign off
        estimated_minutes: null   # TBD

  - id: ceiling
    kind: work_cell
    line: frame-line
    name: Ceiling
    position: 6
    note: Stub — not yet configured.

  - id: walls
    kind: work_cell
    line: frame-line
    name: Walls
    position: 7
    note: Stub — not yet configured.

  - id: s3
    kind: work_cell
    line: frame-line
    name: S3
    position: 8
    note: Stub — S3H integration pending.

links:
  - from: kitchen-podular
    to: transport-lv-vallejo
    sku_filter: SKU-A,SKU-B
  - from: transport-lv-vallejo
    to: receiving
    sku_filter: SKU-A,SKU-B
  - from: receiving
    to: eps-lot-one
    sku_filter: SKU-A,SKU-B
    label: to storage
  - from: eps-lot-one
    to: flooring
    sku_filter: SKU-A,SKU-B
  - from: flooring
    to: ceiling
    sku_filter: SKU-A,SKU-B
  - from: flooring
    to: s3
    label: rework return          # split return path
  - from: ceiling
    to: walls
    sku_filter: SKU-A,SKU-B

four_m_ledger:
  man: []
  machine: []
  method: []
  material: []                   # auto-projected from node consumes/produces
---

# VA Transitional Housing — Factory Operation Plan

**Client:** iMod Systems (Reed Walker)
**Status:** Draft v1 · Wave 1 — Frame Line playable.

---

## Lines

**Frame Line** — the primary production sequence for modular unit frames.
All eight nodes belong to this line. Ceiling, Walls, and S3 are stubs and
will be configured in subsequent waves.

## SKUs

Two unit variants flow through the Frame Line:

- **SKU-A** — Modular Unit, Standard
- **SKU-B** — Modular Unit, ADA

SKU routing is declared on links. Both SKUs follow the same main path;
the rework-return link (Flooring → S3) has no SKU filter and accepts any unit.

## Production Net — Frame Line

Nodes in production order:

1. **Frame Mfg** *(Supplier)* — Livermore, CA. 14-day lead time, weekly
   cadence. Inspection gate: outgoing quality check before shipment.
2. **Transport** *(Transport)* — 90-minute road leg.
3. **Receiving** *(Work Cell, 1 slot)* — Inspection gate: incoming receive
   check. Step: Receive and inspect frame.
4. **EPS Lot One** *(Storage Lot, 10 slots)* — Frames hold here when the
   Flooring bay is fully occupied.
5. **Flooring** *(Work Cell, 3 slots)* — Steps: Install flooring panels;
   Inspect and sign off.
6. **Ceiling** *(Work Cell)* — Stub.
7. **Walls** *(Work Cell)* — Stub.
8. **S3** *(Work Cell)* — Stub; S3H integration pending.

## Links

All main-path links carry `SKU-A,SKU-B` routing. The split return from
Flooring to S3 is label-only (rework return, no SKU filter).

```
Frame Mfg → Transport  [SKU-A,SKU-B]
Transport → Receiving        [SKU-A,SKU-B]
Receiving → EPS Lot One                 [SKU-A,SKU-B]  label: to storage
EPS Lot One → Flooring                  [SKU-A,SKU-B]
Flooring → Ceiling                      [SKU-A,SKU-B]
Flooring → S3                                          label: rework return
Ceiling → Walls                         [SKU-A,SKU-B]
```

## Inspection Gates

- **Frame Mfg** — outgoing gate (leave-factory check before transport).
- **Receiving** — incoming gate (receive and inspect on arrival).

## Four-M Ledger

Not yet populated. Material rows will be auto-projected from node
consumes/produces when PFEP catalog is integrated (Wave 2+).

## Notes / Decisions

- `schema_version: 2` — Wave 1 shape; kinds replace station|buffer types.
- Ceiling, Walls, S3 are declared stubs so the graph is complete
  (split/return links are live) even though those cells are not yet designed.
- Slots on work cells are capacity declarations, not live occupancy counters
  (simulation is Wave 3+).
- Transport duration is a planning estimate; actual transit tracking is Wave 2+.
