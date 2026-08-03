# Node Design Specification
**Product:** flowspec-ops · Factory Operation Plans  
**Status:** Draft v1 (aligned to manifesto + `node_design.svg` + VA dialog)  
**Stack lenses:** Rules of Flow · Lean · PFEP · S-DBR (full kit)  
**Parent doc (creed):** [`docs/manifesto.md`](../manifesto.md) — product why; this file is the **node atom** how  
**Active build path:** §13.1 · §18 (iMod-good-enough)

---

## 1. Purpose

Define the **canonical node atom** used on the Production Net and, later, the sim/Build net and PDF.

Goals:
- Keep the **net card thin** for desk scanning and flow layout.
- Put **Four M depth** (Man, Machine, Method, Material) behind a **side-out**, not on-card bulk.
- Make **full kit** visible as progress (encouragement, not shame).
- Support **shared staff pools** and **dedicated** crews without double-counting.
- One anatomy for **production design** and **trial-run / sim** (same object, different depth).

Non-goals (this spec):
- Full discrete-event engine UX.
- PDF layout details.
- Drag-canvas graph editor.

---

## 2. Design philosophy

| Principle | Application |
|---|---|
| Encouragement, not shame | White → orange → green only. No red “person failed.” |
| Full kit before start | Green = ready to run that M, not “busy.” |
| Thin net, deep detail | Card = structure; side-out = catalogs and status. |
| System over local | Pool contention and commitment gaps are system signals. |
| Portable plan | Everything on the node must round-trip to the factory plan document later. |

---

## 3. Node kinds (unchanged family)

| Kind | Role on the net |
|---|---|
| `work_cell` | Value-add station (Receiving, Flooring, …) — **primary template below** |
| `queue` | Hold (lot, feeding buffer); may join a **storage group** |
| `supplier` | External fab (Frame Mfg) — setup / cadence / vs commitment |
| `transport` | Scheduled batch mover (vendor, route, batch, weekday, transit) |

Storage **group** (e.g. EPS): UI container over queue members with `storage_group`; **total slots = Σ member slots**. Not a separate capacity authority.

Flow **sequence badge** (1, 2, 3…) is **display order after grouping** (EPS group = one badge), not raw DB position per lot row.

---

## 4. Station card (on-net) — what stays thin

### 4.1 Chrome
- Flow sequence badge
- Station name
- **Slots** (planned concurrent units / floor space)
- Optional compact signals already proven useful (e.g. Receiving **In / Need / Gap** when inbound transports exist)
- Optional crew badge only if dedicated or day-summary is needed; prefer pool-driven Man detail in side-out

### 4.2 Step row (required pattern)
For each step, in order:

| Element | Required | Notes |
|---|---|---|
| Step index | yes | 1…n within station |
| Step name | yes | Method |
| Cycle / duration | yes when known | e.g. 45m, 2h |
| Upstream part | when consumes upstream output | Handshake label |
| **Four M dots** | yes | See §5 |
| People demand (`ppl`) | when Man applies | Integer; draws from pool or dedicated |
| Spec lines under step | optional | e.g. `+equip …` (summary); full grid in side-out |

### 4.3 Explicitly not on the card permanently
- Full CONSUMES table
- Full MACHINES / TOOLS table
- Full STAFF POOL roster / calendar
- Long commentary blocks (use note sparingly)

---

## 5. Four M readiness dots

### 5.1 Dimensions (four dots, fixed order)

| Order | M | Meaning on this step |
|---|---|---|
| 1 | **Man** | People defined and coverable (pool alloc or dedicated) |
| 2 | **Machine** | Tools/equipment required are defined and ready |
| 3 | **Method** | Standard/work content defined and usable |
| 4 | **Material** | Consumes / upstream part defined and full-kit ready |

### 5.2 States (three colors — each dot)

| State | Color | Meaning |
|---|---|---|
| Empty | **White** | Nothing defined for this M on this step |
| Specced | **Orange** | Requirements named / designed (spec exists) |
| Full kit | **Green** | Ready to run for this M |

No red. Gaps that block the **commitment** use neutral/amber **system** language elsewhere (e.g. “short N/wk”), not on the person.

### 5.3 Interaction
- **Click a dot** → open **side-out** (§6) focused on that M for this step (and station context).
- Optional later: click step row opens side-out on Method by default.

### 5.4 Roll-up (optional later)
Station-level summary: count of greens / worst M. Not required for v1 card chrome.

### 5.5 Computation policy
Prefer **computed** green when data exists (PFEP availability, tool status, trained+allocated people, method artifact present).  
Manual override allowed temporarily; overrides should be visible in side-out.

---

## 6. Side-out panel

### 6.1 Chrome
- **Right side-out** preferred (net stays visible).
- Modal acceptable for narrow focus; default product choice: **side-out**.
- Title: Station · Step · M tab.
- Close: explicit control + click-away.

### 6.2 Tabs / sections (map to SVG catalogs)

| Section | Opens from | Content |
|---|---|---|
| **Material / Consumes** | Material dot | Grid of consumed items; upstream part links; qty/unit; replenishment discipline (later); line-level Spec→Source→Ready |
| **Machines / Tools** | Machine dot | Equipment/tool rows; +equip specs; readiness |
| **Method** | Method dot | Step definition, time, instructions, attachments (later) |
| **Man / Staff** | Man dot | Demand `ppl`; pool or dedicated source; allocation windows; trained/skill summary |

CONSUMES and MACHINES/TOOLS match the empty grids in `node_design.svg`: structure first, data filled per client.

### 6.3 Row-level status inside side-out
Each consume/tool/person-cover row may show the same white/orange/green progression for that line item.  
Step-level Material/Machine dots roll up from rows (all green → step M green; any white → not green; else orange if any specced).

---

## 7. Staff pool logic

### 7.1 Two supply types

| Type | Definition |
|---|---|
| **Pool** | Shareable headcount (e.g. Rigging = 10). Allocated by area/station and weekday. |
| **Dedicated** | Fixed to a station/area; not available to other draws. |

### 7.2 Pool record (factory-level)
- `name` (e.g. Rigging)
- `headcount` (e.g. 10)
- Optional later: skill tags, trained counts

### 7.3 Allocation rule (example)
- Pool: Rigging  
- Station/area: Receiving  
- Weekdays: Thursday, Friday  
- People: 4  

Mon–Wed (or other days): same pool may be allocated to other tasks/areas.  
**Same-day sum of allocations from a pool cannot exceed headcount** (design check + sim check).

### 7.4 Step demand
- Step declares `people` (demand).
- Step (or station default) declares `staff_source`: `pool:Rigging` | `dedicated`.
- **Man orange:** demand and source defined.  
- **Man green:** source can cover demand on days the step/station runs (alloc ≥ demand for pool; dedicated ≥ demand).

### 7.5 Multi-area contention
If Receiving needs 4 Rigging and EPS Transfer needs 2 Rigging the same day → 6 of 10.  
If another area needs 5 more the same day → **system short**; show on pool side-out / feasibility, not as individual blame.

### 7.6 What stays local on the node
- `ppl` on the step (demand)  
- Optional station `crew_size` only as **dedicated** or temporary shorthand until pools are wired  

What moves to factory staff model:
- Pool headcount, calendar allocations, dedicated rosters, trained/skill matrices  

---

## 8. Material and machine (side-out grids)

### 8.1 Consumes (Material)
Each row ideally:
- Part / SKU / upstream output identity  
- Qty per unit (or per run)  
- Unit  
- Source (upstream node, PFEP, purchase)  
- Replenishment discipline (kanban n-bin, JIS, min/max, kit, cross-dock, consignment, batch-queue) — phase in  
- Readiness white/orange/green  

**Upstream part** on the step is the primary handshake label into this grid.

### 8.2 Machines / tools (Machine)
Each row:
- Equipment / tool identity  
- Qty / needed  
- Readiness white/orange/green  
- Step summary lines may show `+equip …` as shorthand of linked rows  

---

## 9. Method

- Step name + order + duration on card.  
- Side-out: full standard, attachments, notes.  
- Method green: standard exists and is accepted as usable for run (criteria product-defined; start simple: name + time present → orange; documented standard linked → green).

---

## 10. Other node kinds (inheritance)

| Kind | Card body emphasis | Dots / side-out |
|---|---|---|
| **Supplier** | Setup, cadence, vs commitment | Optional M dots later; commitment gap stays system strip |
| **Transport** | Vendor, route, batch, weekday, transit | Usually no Four M row; schedule is the story |
| **Queue / lot** | Slots, location, group membership | Transfer **steps** may sit on group (EPS); dots on those steps |
| **Storage group UI** | Sequence badge, name, **Σ slots**, passthrough row, lot rows, group steps | Same step/dot rules for transfer method |

Passthrough is a **path** (e.g. → (3) Flooring), not storage capacity. Do not add passthrough into Σ slots.

---

## 11. Net vs Build / sim

| Concern | Net (design) | Build / trial run |
|---|---|---|
| Slots, steps, rates, pools, alloc rules | Source of truth | Read-only inputs |
| Commitment target/window | Header | Scenario may bind to same or override qty/dates |
| Dot states | Design readiness | Plus runtime availability when wired |
| Pool calendar | Planned alloc | Day-by-day remaining / contention |
| Crash / patch | Static gaps (short N/wk) | Trajectory, WIP, starvation |

Same node atom both places.

---

## 12. Encouragement language (copy rules)

Use:
- empty / specced / full kit  
- short N/wk, headroom, tight Thursday (system)  
- elevate supply, change promise, add alloc  

Avoid:
- red fail on people  
- utilization % as a goal on non-constraints  
- “understaffed crew” as moral judgment  

---

## 13. Implementation phases

### 13.1 iMod-good-enough path (active — see §18)
Build order for mapping iMod under time/cost pressure. Each phase: write thin claims in this doc → conflict check → implement → Michael tries on iMod → feedback.

| Phase | Deliverable |
|---|---|
| **0** | iMod MVP checklist + scope freeze (this section’s partner: §18) |
| **1** | Card face chrome (header, andon placeholder, bottom band, light inline) |
| **1b** | **Safety:** confirm on destructive delete; stop accidental abacus × wipes |
| **2** | Kanban movement + step roles (value/setup/swap) |
| **3** | Need signal + andon math (need · can · short) |
| **4** | Capacity group nest (concurrent \| ping_pong); master andon precedence |
| **5** | Staff demand roll-up good enough for PDF/print |
| **6** | Only if iMod still blocked (light pool alloc or consumes hole) |
| **V** | **Save + versions** for factory plans (see §13.3) — required before heavy iMod editing |

### 13.3 Save and versions (planned — critical)
**Why:** Hard delete of Flooring + S3 during abacus play showed live DB edits are one click from losing the plan. Seeds are not a version store. Portable factory plans need **named saves** and **history**, not only auto-persist.

**Product intent (MVP shape — grill before build):**
1. **Explicit save point** — designer can snapshot the current net (nodes, steps, links, commitment, groups, gates) as a **version**.  
2. **Version list** — name/timestamp/note; open/restore a prior version without seed reset.  
3. **Working copy vs published** (optional v1) — keep playing on draft; promote a version as “current plan” for PDF/trial.  
4. **Destructive ops** — delete node/step always **confirm**; prefer soft-delete or trash within a version later.  
5. **Not git for operators** — versions live in-app (DB), exportable later to `.factoryplan.md` / JSON.

**Placement in build order:** After Phase 1 chrome is usable, **prioritize V / 1b before deep iMod data entry** (or immediately when mapping starts in earnest). Do not wait for Four M path.

**Open design questions (resolve when Phase V starts):**
- Snapshot granularity: whole factory only vs line-level?  
- Auto-save draft every N minutes vs manual Save only?  
- Restore = replace working copy, or fork new draft?  
- How versions relate to PDF export and trial-run scenarios.

### 13.2 Longer-horizon Four M path (after iMod map)
Deferred product depth — do not block iMod on these.

| Phase | Deliverable |
|---|---|
| **F1** | Four M dots on work_cell steps (manual state); click → side-out shell with tabs |
| **F2** | Consumes + machines rows in side-out; upstream part on step; step specs → rows |
| **F3** | Staff pools + allocations; Man green from cover rules; dedicated flag |
| **F4** | Computed greens where data exists; commitment/pool feasibility strips |
| **F5** | Build/sim consumes same model |

---

## 14. Acceptance checks (definition of done for the design)

1. Station card remains scannable at ~18.5rem width with steps + dots + ppl.  
2. No full consumes/tools/pool tables permanently on the card.  
3. Each step has four dots; states are only white / orange / green.  
4. Dot click opens side-out on the correct M.  
5. Rigging-style pool can show headcount 10 and Thu/Fri alloc 4 to an area without implying those 4 are free elsewhere the same day.  
6. Dedicated staff cannot be used to cover another station’s pool demand.  
7. EPS group: one flow sequence number; Σ slots; passthrough ≠ slots; transfer steps visible.  
8. Language matches encouragement / full-kit framing.

---

## 15. Open points (resolve in dialog, not silent defaults)

1. Dot placement default: **per step** (recommended) vs station-only.  
2. Method green criteria v1 (time+name vs linked standard).  
3. Whether Receiving “In/Need/Gap” remains on-card when dots exist (recommended yes — commitment signal, not an M table).  
4. Pool UI home: factory-level Staff list vs only inside Man side-out.  
5. **Home object v1:** building/program first vs factory net/product family first vs full-kit board first.  
6. **Sacred full-kit gate v1:** into-net release vs per-station card vs site/install handoff (all may exist later; pick one primary).  
7. **Setup cadence assumption** per station standard: per transfer-batch vs per day vs per unit.  
8. **Panel WO vs install buffer split:** factory ship-buffer to install need-date vs one buffer story across both.  
9. SVG **WK** row and manpower **hours**: off thin card unless tied to planned-load / cover (not utilization %).  
10. **Save / versions** model details (§13.3) — snapshot vs auto-draft, restore semantics.

---

## 16. References

- **Manifesto (parent):** [`docs/manifesto.md`](../manifesto.md) — Factory Operation Plans · Production Net · Four M’s · Spec→Source→Ready · trial run · encouragement · hybrid program/factory  
- Visual: `docs/design/node_design.svg`, `docs/design/node_design_spec.svg`  
- Related UI already in product: commitment header, line spines, EPS storage group, supplier vs commitment, transport schedule, step `people` / `specs`  
- TOC anchors: Goldratt DBR/CCPM; Schragenheim & Dettmer *Manufacturing at Warp Speed* (S-DBR, planned load); Rules of Flow (knowledge-work / program layer)

---

## 17. Working session notes (2026-08-02) — capacity, kanban, hybrid

**Status:** Provisional design direction from dialog. Not fully locked. Resume here.

### 17.1 Product hypothesis (Flowspec Ops)
Complex buildings are **hybrid**:
- **Program layer:** CCPM / Rules of Flow (projects, bad multitasking limits, project buffers, full kit to start a phase/task).
- **Factory layer:** S-DBR / DBR (repetitive units — e.g. ~1000 panels, ~5000 servers mfg + install kits).

Same customer/building **due-date promise**; **two control regimes**; **full kit is the join** at handoffs (e.g. panels ready for install window).

**Tool purpose (MVP minimum):** (1) **Can this line meet customer demand, quickly?** (2) **If yes, Four M’s to fulfill the timing — PDF sum of what to acquire / place / contract.** Full kit backward from due date. Not a labor timesheet; not a project Gantt. More capability later; these two jobs gate MVP.

### 17.2 Intended design sequence (factory slice)
1. Commitment / due date (drum).  
2. Design the **net** and the **full kit that satisfies** the promise.  
3. Process content + **process batch** vs **transfer batch** + stop rules.  
4. Planned load → find **CCR**.  
5. Place **feeding / ship buffers**.  
6. Adjust staffing (cover), transfer batch size, etc.  
7. Trial run / buffer signals later (execution ≠ redraw planning net as timesheet).

### 17.3 Planning sheet posture (agreed direction)
- This is a **planning baseline**, not a management/variance scorecard.  
- Setup and transfer are **known process cost** in the standard, not KPIs to chase.  
- Crew **starts when full kit arrives**; stops for **not full kit** or **card complete**.  
- Kanban: **only what is on the card — not more** (e.g. do 3 → transfer → stop).  
- Variances will exist; **do not instrument this sheet** to measure people efficiency.  
- **Not project management:** production touch time ≪ lead time; buffers absorb noise; critical chain is the wrong primary model for the repetitive slice.

### 17.4 Batch language (agreed)
| Term | Meaning |
|---|---|
| **Process batch** | How many worked as a set at the station (“do 3”) |
| **Transfer batch** | How many moved when the card says move |

May be equal or different. SVG “Batch 3×” must not silently mean slots × cycle only — policy qty is first-class.

### 17.5 Station math on `node_design_spec.svg` (as drawn)
- Step times + ppl (e.g. 45m/4, 2h/4) → **Ea** (e.g. 2h 45m).  
- Batch row (e.g. 3× → 8h 15m) = content for that process qty (clarify vs slots).  
- **WK** row present but empty.  
- Callout path: staff alloc → deliverable units (planning feasibility, not utilization goal).  
- Still to model cleanly: **setup steps**, **shutdown/transfer steps**, **day envelope** if needed for planned load — without turning manpower into occupancy %.

### 17.6 Manpower / staff pool
- Keep: headcount, skill, trained, **alloc by day/area**.  
- Hours on sheet only if framed as **supply for cover / planned load**, never utilization % on non-constraints.  
- Prefer system language: short N/wk, tight Thursday, headroom.

### 17.7 How Goldratt / Schragenheim would build the net (summary)
- Flow of **material** + promise, not org chart or full resource schedule.  
- S-DBR default: market drum, shipping time buffer, rope at **release**, planned load on weakest link.  
- Internal CCR only when real: protect from starvation; do not finite-schedule all non-constraints.  
- VAT shape awareness; process vs transfer batch; protective capacity is a feature.  
- Execution = buffer management / full-kit compliance — separate from planning baseline.

### 17.8 Resume checklist
Superseded for build order by **§18 Phase 0**. Remaining open points (home object, sacred gate, hybrid buffer split) stay deferred unless iMod data forces them.

---

## 18. Phase 0 — iMod MVP checklist (review)

**Status:** **Closed 2026-08-02** — C1–C5 locked; conflicts cleared or residual-deferred; §13.1 active. No feature code in Phase 0.

**Purpose of Phase 0:** Freeze what “good enough to map iMod” means, what we will not build yet, and the collaboration rule for later phases. No feature code in Phase 0.

### 18.1 Success definition (iMod map)

**MVP north star (product minimum — see manifesto §2):**

1. **Demand fit, fast** — Can this production line meet customer demand? Net + abacus + andon answer quickly.  
2. **Four M fulfillment list** — If numbers look right, what Man / Machine / Method / Material must we acquire, place, or contract? **PDF sums that list**; **CSV** for purchasing/acquisition (equip + materials). Later: hand list to Roger / Flowspec app → actual PO lines. Net = **spec + budget**, not the buy system.

We are done with the iMod-good-enough path when all of the following are true:

1. Full iMod factory spine can be entered as lines / nodes / steps / batches **without a spreadsheet side channel**.  
2. Designer can **scan the net** and see where the plan is **short vs the promise** (andon / abacus).  
3. A capacity bank can express **ping-pong (e.g. 4 ppl, 6 slots, wave 3)** vs **concurrent (e.g. 8 ppl)** without lying on staff or rate.  
4. **PDF-honest roll-ups** for staffing (and path to full Four M acquisition sum): Σ rate ≠ Σ people; mode-aware.  
5. Face stays a **live projection**; edits via inline (light) or fast popup (heavy); net remains visible while playing capacity.  
6. Spec sections for build phases are written **as those phases run**, each surviving a conflict check before code.  
7. Scope discipline: features that don’t serve **(1) demand fit** or **(2) Four M PDF sum** wait.

### 18.2 In scope (must work for iMod)

| Area | MVP claim |
|---|---|
| **Net spine** | Existing node kinds: work_cell, queue, supplier, transport; links; storage groups as today |
| **Face chrome** | Sequence badge · station/bank name · optional **[G]** (gold, left of circle) · **●** status circle (header right) · bottom **abacus** |
| **Kanban** | Process batch, transfer batch, stop; kanban movement popup |
| **Steps** | Name, order, minutes, people; station steps include crane/transfer as **work content** (not receive — receive is upstream) |
| **Defaults** | Calijane-style demo values that still calculate; default vs committed distinction on face |
| **Andon** | **Bare colored circle only** (no “Andon” word on the face), driven by **bottom abacus**: **white** = not enough data; **orange** = bottleneck; **green** = no blocks / design allows flow |
| **Capacity group** | Minimal-chrome master nesting station cards; header click → mode popup; master andon precedence |
| **Staff mode on master** | Header popup: method · **parallel** · **series** (ping-pong/wave); declared on **master only** |
| **Swap / crane** | On **station** card as step(s) with crew via popup; storage/buffer cards stay hold/passthrough geometry |
| **Staff / PDF** | Peak ppl per member; bank roll-up by mode; simple demand list/print — not full pool calendar |
| **Gate [G]** | Designer-set gold mark **immediately left of the status circle**; marks CCR / S-DBR control point / iMod stop signal (e.g. flooring slots) — mechanics TBD |

### 18.3 Out of scope (freeze until after iMod map)
- Full Four M **computed** greens, PFEP wiring, deep consumes/equip catalogs (unless a single hole blocks iMod — Phase 6 only)  
- Production **sim / trial-run engine** and buffer-management execution UI  
- **Month** on station face; utilization %; variance / efficiency KPIs  
- **Alternate** staffing mode UI beyond concurrent \| ping_pong  
- Heavy **pool calendar** product; multi-area contention optimizer  
- Program-layer **CCPM** UI (hybrid remains hypothesis; factory slice first)  
- Polished component directory beyond what each phase naturally creates  
- Multi-agent orchestration / remote runners for this path (SOHO: one local cheap builder)

### 18.4 Face contract (locked for MVP)

```text
FACE  = read model, always derived, scannable on the net
WRITE = inline light scalars OR fast popup for structured objects
MASTER (capacity group) = minimal chrome · mode popup · andon authority · staff roll-up
MEMBER station     = local steps (incl. crane/transfer) · abacus · own capacity
STORAGE / buffer   = hold, slots, passthrough — not workstation process steps
```

Header (left → right): sequence · name · … · optional **[G]** gold gate · **● circle** (no word “Andon”).  
**[G] sits immediately left of the circle** (header-right cluster), not beside the sequence badge.  
Bottom **abacus** = configured capacity geometry (batches, times, crew, slots as applicable) — **drives** the circle.  
Circle is **not** a D/W/M caption; D/W/M (if shown) live in the abacus as inputs/outputs to the light.  
Month stays off the card as a third status mode.

### 18.5 Math / honesty rules (locked for MVP)
1. **Process batch ≠ transfer batch** unless set equal; neither is silently “slots × cycle.”  
2. **Ea** = sum of **value** step times (per unit or per agreed base — lock in Phase 2).  
3. Crane/transfer on a **station** is a **step** with people (e.g. 2 rigging) via popup; **receive** is upstream (e.g. from storage), not a receive-step on the station face.  
4. **Status circle** is computed from whether the **abacus has enough data** and whether design capacity **allows flow** vs bottleneck — white / orange / green (see §18.6).  
5. **Staff demand:** parallel/concurrent → Σ member peaks; series/ping-pong → shared crew; never imply 4 when two concurrent 4s run.  
6. Shared **pool** cover checks against true concurrent draw; Σ output must not fake cover.  
7. Defaults teach; **committed** values are what the plan means for PDF and circle once touched.  
8. **[G] gate** is a designer-placed control-point mark **to the left of the status circle** (CCR, ship drum, or iMod stop such as flooring slots empty → rigging stop). Programming of gate behavior = TBD after net exists.

### 18.6 Confirms C1–C5 (locked 2026-08-02)

| ID | Decision |
|---|---|
| **C1 + C2 Andon** | Andon = **bare colored circle** (header right) — **no “Andon” caption** on the face; not a day/week/month picker. **White** = not enough data. **Orange** = bottleneck. **Green** = no blocks (design allows flow). Driven by the **bottom abacus** — abacus feeds the light above. Optional tooltip/title for accessibility only, not visible chrome text. |
| **C3 Crane / station vs storage** | Two scenarios: (1) **Station card** (not storage/passthrough/buffer): has workstation capacity; **crane/transfer is a step** on that card with crew assigned in popup (e.g. 2 rigging). Station does **not** carry a “receive” step — receive is **upstream** (e.g. flooring storage card). (2) **Storage / passthrough / buffer card**: hold/slots/path geometry, not the workstation process abacus. **Both** card families needed on the net. |
| **C4 Group / mode** | When **two station cards** sit in a **minimal-chrome group** master: click **header** → popup for **method · parallel · series**. (Series covers wave/ping-pong-style crew sharing; parallel = concurrent cover.) |
| **C5 Gate** | Denote gate as **[G] in gold immediately left of the status circle** (header-right cluster), set in popup. Placed when net is built and designer decides CCR / S-DBR ship control / stop signal. **iMod now:** gate story includes **available flooring slots** — no slots ⇒ stop signal for rigging bringing more frames into the factory. **Mechanics TBD** in code; mark + placement first. |

### 18.7 Collaboration rule (every later phase)
1. Write this phase’s thin claims into §18.x / §19+ in this file.  
2. Ask: **Does this work, or is there a conflict?** (TOC, staff PDF, kanban, iMod data, existing code.)  
3. Dialog → fix, defer with note, or change phase boundary.  
4. Implement one vertical slice only.  
5. Michael applies iMod data / clicks the net.  
6. Feedback on **that slice only**; patch or next phase.

### 18.8 Phase 0 acceptance (this phase done when)
- [x] §18 reviewed by Michael (C1–C5 locked)  
- [x] Conflicts named below resolved or residual-deferred  
- [x] C1–C5 answered  
- [x] §13.1 accepted as active build order  
- [x] No feature code started before Phase 0 close  

### 18.9 Conflict review

| # | Tension | Cleared by C1–C5? | Status |
|---|---|---|---|
| **1** | §13.2 Four M path vs §13.1 iMod path | **Partial** — answers didn’t reopen Four M; still a process discipline | **Cleared by rule:** iMod path wins until map exists; F-path not next sprint |
| **2** | Receiving **In/Need/Gap** vs **andon circle** | **Mostly** — andon is abacus-driven circle (flow/bottleneck/data), not a second D/W/M caption | **Open thin rule:** keep In/Need/Gap as **inbound transport** strip where it exists; andon stays **header circle** from abacus. Do not merge in Phase 1 unless they collide on one card in iMod. |
| **3** | `crew_size` vs pool + mode | **Partial** — C3 assigns crew on crane/transfer via **step popup**; C4 mode on group header | **Cleared for MVP:** step `people` + group mode popup; full pool calendar still out of scope. `crew_size` may remain shorthand until pools. |
| **4** | Storage group vs capacity/station group | **Yes** — C3 splits station vs storage/buffer cards; C4 is station cards inside minimal-chrome group | **Cleared:** different card families + different roll-ups; **do not** reuse `storage_group` field for station banks — new key name in Phase 4 (e.g. `capacity_group` / `cell_group`). |
| **5** | §15 open points 5–9 | **Partial** — C5 places **[G]** as control-point mark; sacred-gate programming TBD | **Cleared enough for iMod mark:** [G] on header; flooring-slots stop story noted. Deep rope automation deferred. |

**Residual opens (do not block Phase 0 close if accepted):**
- Exact andon formula thresholds (what tips orange vs green) — lock in Phase 3 with real abacus fields  
- Gate runtime behavior (auto stop vs design-time mark only) — TBD  
- In/Need/Gap + andon on same Receiving card — watch in Phase 1 UI  

**Michael / joint notes:**
- Andon = circle; abacus drives light; not D/W/M mode switch  
- Station carries crane/transfer step + crew; receive stays upstream storage  
- Group header popup: method · parallel · series  
- [G] gold immediately left of status ●; iMod: flooring slots as stop signal for rigging/frames  

---

## 19. Phase 1 — Card face chrome (claims for conflict review)

**Status:** Draft claims. **No UI code until Michael clears conflicts below.**  
**Slice goal:** Make the work-cell **face** scannable: header frame + andon circle + bottom abacus **shell**, with placeholder andon logic only. Deep kanban math, group modes, gate runtime = later phases.

### 19.1 Scope (this phase only)

| In | Out |
|---|---|
| **work_cell** face header + footer chrome | Supplier/transport redesign (keep as-is) |
| Sequence · name · optional **[G]** · **●** (gate left of circle) | Capacity group nest (Phase 4) |
| Bottom **abacus shell** (labels + whatever data already exists) | Process/transfer batch fields + kanban popup (Phase 2) |
| Andon **placeholder states** from crude data completeness | Real orange/green bottleneck formula (Phase 3) |
| Keep existing step list + add-step | Step roles, crane popup depth |
| Keep **In/Need/Gap** strip when inbound transports exist | Merging In/Need/Gap into andon |
| Optional light inline later if trivial | Staff PDF, pools, Four M dots |

### 19.2 Target face (work_cell)

```text
┌──────────────────────────────────────────────┐
│ (2)  FLOORING                      [G]? ●  │  ← header: name left; [G]+● right
├──────────────────────────────────────────────┤
│ In / Need / Gap   (only if inbound xport)  │  ← keep existing strip
├──────────────────────────────────────────────┤
│ 1  step …                         min  ppl │  ← body unchanged this phase
│ 2  …                                       │
│ + step                                     │
├──────────────────────────────────────────────┤
│ ABACUS                                     │  ← footer shell
│ Ea · batch · xfer · stop · slots · crew    │     show available numbers;
│ (placeholders / — until Phase 2 fields)    │     teach with defaults later
└──────────────────────────────────────────────┘
```

Header L→R: **sequence badge** · **name** (truncate, flex) · **[G]** if gate flagged · **●** (color only).  
**[G] is immediately left of the circle** — one header-right cluster.  
**No “Andon” (or other status word) beside the circle** — color is the signal.  
Remove header-right **crew N ppl** as the primary right affordance (crew moves toward abacus / steps); do not fight [G]● for the corner.

### 19.3 Status circle (Phase 1 behavior — placeholder)

Internal name may stay “andon”; **on-face chrome is color only.**

| State | Look | Meaning |
|---|---|---|
| **Not enough data** | **White** (empty / light ring OK) | Missing data to calculate |
| **Bottleneck** | **Orange** | Bottleneck (full rule in Phase 3; P1 does not fake this) |
| **No blocks** | **Green** | Design allows flow / no blocks (full rule in Phase 3; P1 does not fake this) |

**Phase 1 rule:** Prefer **honest white** over fake green or orange. Real orange/green in Phase 3 when abacus can drive the judgment. Circle is always **visible** so the chrome is learnable.

Optional `title` tooltip for accessibility only (e.g. “Need data” / “Bottleneck” / “No blocks”) — **not** painted label text on the card.

### 19.4 Gate [G] (Phase 1 behavior — mark only)

- Gold **[G]** (or compact gold badge) **immediately left of the status circle**, only when `gate == true` (or equivalent flag).  
- Phase 1: **display if flag present**; setting flag may be a minimal control (node note/checkbox/popup stub) **or** seed/admin only if faster — prefer one obvious toggle so iMod can mark flooring-slots gate.  
- **No** rope/stop automation in Phase 1.

### 19.5 Bottom abacus shell (Phase 1)

Replace the ad-hoc footer (`steps · slots` / `expected_in vs need` / `crew < peak` jumble) with a **named abacus band**:

| Cell | Phase 1 source |
|---|---|
| **Ea** | Sum `estimated_minutes` on steps (format as Xm or h:m) — already have `est_total` |
| **Batch** | `—` until Phase 2 field (optional demo default muted) |
| **Xfer** | `—` until Phase 2 |
| **Stop** | Static label `stop` or `—` (policy text later) |
| **Slots** | `node.slots` if set |
| **Crew / peak** | `crew_size` and/or peak step people — secondary, not header andon |

Abacus is **read projection** in Phase 1; no kanban popup yet. Muted styling for uncommitted / missing cells (calijane teach direction without inventing fake throughput).

### 19.6 Data / code touch (when approved)

- Primary: `work_cell_card/1` in `lib/flowspec_ops_web/live/factory/show_live.ex`  
- Likely small: boolean `gate` (or reuse something only if clean — **prefer explicit `gate` on factory_nodes**) + migration  
- **No** new batch columns until Phase 2  
- Storage group / queue / supplier / transport cards: **no** required change in Phase 1 (andon on work_cell first)

### 19.7 Acceptance (Phase 1 done when)
1. Work-cell header shows sequence · name · optional [G] · ● (gate immediately left of circle).  
2. Andon defaults to white/dotted when data thin; never false green.  
3. Footer reads as **abacus** (Ea + slots/crew + placeholders for batch/xfer).  
4. Existing steps + In/Need/Gap still work.  
5. Michael can scan an iMod work_cell and see the new chrome without group/kanban features.  
6. Compile clean; no Phase 2+ scope sneak-in.

### 19.8 Conflict check — does this work?

| # | Possible conflict | Proposal |
|---|---|---|
| **P1-a** | Footer today doubles as intake summary (`in vs need`) | Keep **In/Need/Gap** in mid strip; abacus footer = process geometry. Intake summary text leaves footer. |
| **P1-b** | Crew on header vs andon corner | Crew leaves header right; andon owns corner; crew on abacus/steps. |
| **P1-c** | Gate needs DB field | Add `gate` boolean default false — smallest path. |
| **P1-d** | Fake andon colors too early | Phase 1 = white/dotted dominant; orange/green only if we explicitly keep them off until Phase 3. |
| **P1-e** | Storage cards without andon look “left behind” | Accept for P1; station scan first for iMod. |
| **P1-f** | Width ~18.5rem — [G] + andon + name crowding | [G] compact; name truncates; andon fixed size-2.5 ring. |

**Michael / joint notes (add during review):**

-  

### 19.9 Proceed rule
After conflicts on §19 cleared → implement **only** §19.6 → Michael clicks iMod net → feedback on chrome only → then Phase 2 claims.

---

*End of draft v1 + session notes + Phase 0 closed + Phase 1 claims.*
