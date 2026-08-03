# Flowspec Ops — Manifesto

**Product:** flowspec-ops · domain `ops.flowspec.co`  
**Status:** Living product creed (harvested from design dialog + node spec themes)  
**Not this doc:** node card mechanics, phase checklists, or implementation order — see `docs/design/node_design_spec.md`

---

## 1. What we are building

**Factory Operation Plans** — the operational home for designing how work will flow before (and while) the building is delivered.

The primary artifact is the **Production Net**: a portable plan of stations, queues, suppliers, transports, kits, people, and promises. The same node atom later supports **trial run / sim** and **PDF** illustration (staffing demand, spine, commitment). The net is a **planning baseline**, not a labor timesheet and not a project Gantt wearing factory clothes.

---

## 2. The job to be done

### MVP minimum (two jobs — NBR: everything else is later)

1. **Can we build this production line to meet customer demand — quickly?**  
   Design the net, play capacity (abacus, feeds, sequence, batches, staffing modes), and see **need vs can** (andon / short N). Answer is a **planning feasibility** read, not a shop-floor scorecard.

2. **If the numbers look right — what are the Four M’s required to fulfill that timing?**  
   Spec Man · Machine · Method · Material to support the plan, then a **PDF that sums what must be acquired, put in place, or contracted out**.

**Acquisition path (Machine / materials especially):** the net is **spec + budget**. Export a **CSV shopping / acquisition list** for purchasing. Later, production sim can hand that list to **Roger / the Flowspec app**; they return **actual items to purchase**. Ops plans the need; acquisition systems close the buy.

The tool can grow (sim, CCPM program layer, deep PFEP). **MVP is not those.** MVP is: **fast line-vs-demand confidence → Four M acquisition list on paper (and CSV).**

### How we work backward (factory slice)

Full kit, **backward from the customer due date / commitment**:

1. Commitment / due date (drum)  
2. Design the net (stations, feeds, sequence) so demand is plannable  
3. Process content · process batch vs transfer batch · stop rules · abacus  
4. Planned load → weak link / bottleneck signal  
5. Place feeding / ship buffers as needed  
6. Four M depth for the timing that survived step 1–5  
7. PDF roll-up: people, equipment, method standards, materials — buy / place / contract  
8. Trial run / buffer signals later — execution is not the MVP gate  

---

## 3. Hybrid reality (complex buildings)

Complex buildings are **two physics under one promise**:

| Layer | Engine | Examples |
|---|---|---|
| **Program** | CCPM / Rules of Flow | Phases, bad multitasking limits, project buffers, full kit to *start a phase/task* |
| **Factory** | S-DBR / DBR | Repetitive units — panels, frames, servers mfg + install kits |

Same customer/building **due date**. **Full kit is the join** at handoffs (e.g. panels ready for an install window).

Do not collapse knowledge-work control into touch-time production scheduling, or run a panel line like a task network.

---

## 4. Lenses (always on)

- **Rules of Flow** — protect flow in knowledge work; limit bad multitasking  
- **Lean / kanban** — only what is on the card; do N → move → stop; no fill-the-shift  
- **PFEP** — plan for every part; material readiness is designable  
- **S-DBR / DBR** — drum = promise; rope at release; buffers protect; planned load on the weak link  
- **Throughput Accounting** — T first; no cost-world utilization goals on non-constraints  
- **Four M’s** — Man, Machine, Method, Material as full-kit dimensions (depth behind the thin net)  
- **TWI stance** — build process together; corrections are process data  

---

## 5. Core product moves

### Production Net
Thin cards for desk scan and flow layout. Structure on the face; catalogs and CRUD in side-out / fast popups. Face stays a **live projection** while the designer plays capacity.

### Spec → Source → Ready (Build-to-test)
Name the requirement, attach the source, reach ready/full kit. Progress is **encouragement**, not shame.

### Full kit before start
Green means **ready to run**, not “busy.” Crew starts when kit arrives; stops for missing kit or card complete. Starvation is a **system** signal.

### Encouragement, not shame
White → orange → green on readiness. No red “person failed.” Gaps that block the promise use **system** language (short N/wk, headroom, tight Thursday).

### System over local
Pool contention, path shortfalls, and commitment gaps are system signals. Protective capacity on non-constraints is a feature. Idle waiting on full kit is often correct subordination.

### Portable plan
What appears on the net must round-trip to the factory plan document / PDF: **demand vs capacity story** plus **Four M acquisition sum** (honest staffing: Σ rate ≠ Σ people; concurrent vs ping-pong; machines, methods, materials to acquire or contract).

### Trial run
Same node atom as design; deeper runtime signals later. Do not invent a second model of the factory for sim.

---

## 6. What this is not

- Not a **management variance** sheet (efficiency %, utilization goals, person scoreboards)  
- Not pure **project management** for the repetitive slice (touch ≪ lead time; buffers absorb noise)  
- Not **MRP theater** that releases partial kit to keep machines busy  
- Not a dual intake world — one capture path into the system of record (see project `WARP.md`)  

---

## 7. Language we prefer

Use: empty / specced / full kit · short N/wk · headroom · elevate supply · change promise · add alloc · process batch · transfer batch · stop · andon (need · can · short)

Avoid: red fail on people · utilization as goal on non-constraints · “understaffed” as moral judgment · silent double-counting of crew across parallel faces  

---

## 8. Child specs

| Doc | Role |
|---|---|
| `docs/design/node_design_spec.md` | Canonical **node atom**, face chrome, andon, kanban, capacity groups, iMod MVP phases |
| `docs/design/node_design.svg` / `node_design_spec.svg` | Visual working drawings |
| `docs/samples/*.factoryplan.md` | Example factory plans |

When node mechanics change, update the node spec. When **why we build** changes, update **this** manifesto.

---

*Harvested 2026-08-02 from node design dialog and spec themes. Expand with client-facing manifesto prose as needed; keep implementation detail out.*
