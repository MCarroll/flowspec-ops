# Data Center Skid Configurator (CUED — not yet built)

**Status:** Cued 2026-10-12. Nothing built. Wireframe for discussion below.

## Intent (locked from conversation)

A module within FlowspecOps (Elixir/LiveView) — NOT a throwaway HTML tool.
Prototype the UI in a standalone HTML page first as a *spec*, then build it as a
LiveView surface reachable from the app's **left menu**. The FlowSpec-Ops supply-chain
integration is profound and must not be abandoned: the configurator's output is the
same object the supply-chain model consumes.

The moat offer is **speed-to-decision** (proceed-or-walk), not speed-to-estimate.
Headline output is an investment-grade verdict + confidence, not just capex line items.

## The two tools chain

```
[ Configurator ]  → physical: capex, working capital (I), RT lead times
        ↓  (feeds S-DBR spine)
[ Throughput deck ] → financial: T, I, OE, ROI, shipping buffer, window-hit date
        ↓
[ Verdict ]  → PROCEED / MARGINAL / WALK + the coefficient that decides it
```

## Scope of a single estimate

Whole-kit, living coefficient base: PDU, CDU, DDU, Compute (B300-class), Housing,
Design, Permitting, Power, Interconnection, Land, Data/Fiber, Seismic, Fire, Transport.

## Wireframe (for discussion — ASCII, pending approval)

```
┌──────────────────────────────────────────────┐
│ LEFT MENU  │  DC SKID CONFIGURATOR           │
│ ┌────────┐ │ ┌──────────────────────────────┐│
│ │ ...     │ │  DRUM INPUTS      (sliders)   ││
│ │ Projects│ │  Racks:      [----o----] 140  ││
│ │        │ │  kW/rack:    [-----o---] 45    ││
│ │ NET     │ │  GPU gen:    ( B300 ▼ )       ││
│ │ [Config]│ │  Tenant kW+date: [ 25 MW / d ] │
│ ├────────┤ │ └──────────────────────────────┘│
│ │ DC SKID │ │  COEFFICIENT SHEET  (editable) │
│ │  Config │ │  PDU.. Transport .. Permits    │
│ │  (new)  │ │  ─ each row: value + SOURCE    │
│ └────────┘ │ └──────────────────────────────┘│
│            │  ⚠ RED "insufficient data" state │
│            │  when any required coeff unsourced│
│            ├───────────────────────────────────┤
│            │  VERDICT:  PROCEED ⬤ / MARGINAL  │
│            │  │  confidence: high (coeffs sourced)│
│            │  │  payoff:   ROI 302% · 3.5 mo    │
│            │  │  walk-killer: permit lead 120d  │
│            └───────────────────────────────────┘
```

## Anti-speculator gate (hard requirement, enforced in UI)

- Configurator refuses to run without a **committed tenant kW + date** (D1).
- Refuses to emit a verdict when any required coefficient is **unsourced** — shows
  RED state naming the missing coefficient, not a fake number.
- **Estimate ≠ quote.** Tool produces estimates only; real commitment requires
  engineering review. Keeps the recurring-revenue consulting role alive.

## Rules of Flow / S-DBR mapping (from datacenter-sdbr-model-schema.md)

- Drum = committed kW / racks (machine/resource CCR — GPU + power + permit path,
  NOT the crew). Crew is the constant.
- RT = GPU lead(90d) + frame(28d) + power/permit(120d) + internal skid cycle(14d).
- Shipping buffer = shippable-rack window protecting the tenant go-live; red/yellow/
  green = window protection, target 98.5% hit rate.
- Fair-labor floor is a HARD constraint — never tuned around.

## Build path (deferred until discussion)

1. Standalone HTML prototype = the spec (editable coeff sheet + sliders + verdict).
2. Review wireframe above, approve.
3. LiveView surface, mounted under the left menu (configurator route).
4. Wire configurator output → throughput-deck S-DBR calc → FlowSpec-Ops cards.

## Cross-refs

- `investment-sdbr-factory-model.md` — the screwdriver-scale S-DBR/TA foundation.
- `datacenter-sdbr-model-schema.md` — the DC-flavored JSON schema (v1).
- Skill: `flowspec-ops-development` (left-menu placement to confirm against app).
