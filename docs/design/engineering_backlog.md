# Flowspec Ops — Engineering Backlog

**Status:** Living priority list (harvested from design dialog 2026-08-06)  
**Product north star:** Show what it takes to spin up **iMod VA Factory** — fast enough for investors, honest enough that manpower is not two-people-per-station folklore.

Not phase checklists for card chrome — see `node_design_spec.md`. This file is **eng tracks** that must not get lost in chat.

---

## Locked product posture (2026-08-06)

### PDF — iteration weapon, expert readers

- **Primary job:** Radically show what it takes to stand up the factory (people, stations, 4M, abacus geometry).
- **Primary use:** Iteration tool emailed to **Reed** (biz owner), **Roger**, **Robert** (architect) — and used with investors as “good enough to ask / flexible enough not to shut down from ignorance.”
- **Battle being fought:** Stupid manpower assumptions (e.g. two people per station) with no cost-of-turning-up-each-station honesty.
- **Audience:** Adults / experts. **No explainer prose.** Clear simple design + **tables you can pencil-challenge** so the model gets updated.
- **Scopes:** whole project summary · line · single card (on demand).
- **Sections (projection of the net, not a second model):**
  - Abacus (always — geometry / D·W·M / need·can·short as data exists)
  - Manpower grid (people, skills, cover — mode-honest: concurrent ≠ Σ faces)
  - Four M consolidation (acquire / place / contract) — **include as tables even when zeros**
  - Optional line/card cut of the same
- **Empty / early net:** **Print still works.** Zeros and placeholders are a **full-kit signal without saying “not full kit”** — empty cells show where the plan is still open. Sample “show me” structure, lorem where labels teach shape, **0s/1s** on abacus until real data lands.
- **Pencil away from screen:** print a **single card** (or line) and mark it up when not at a keyboard; feed marks back into the model later.

### Versions now · multi-editor surface later

- **Need versions** (undo / restore) for safe iMod editing and workshop baselines.
- **v1 operating model:** **Michael is the only Editor.** Workshop loop = print · get involvement · present on large display / screen share · **Michael changes the net in realtime**. Partners challenge with pencil/voice; they do not hold the write path yet.
- **Schema now, surface later:** Editor · Reader (and simple change log: what / who) is a **path we must not lock out** — model the roles in data when versions land. **Shared multi-user edit surface = v2.** Do not build invite/magic-link collab UI in v1.
- **Framing:** Michael’s consulting tool; intimate circle; not multiplayer product yet.

### Whisper → CLI — constant efficiency pressure (not a near sprint)

**Clarified 2026-08-06:** This is a **gradual tooling upgrade for Michael**, not a product feature race and not “build Whisper app now.”

- **When the app is stable enough**, CLI becomes a faster capture path than clicking every field.
- **Flow:** Whisper (or any STT) → **text** → CLI takes natural-language instructions → parses against **this** domain (cards, lines, project spin-ups) → applies or **asks clarifying questions**.
- CLI **knows the system** — NL translated to the same domain mutate functions the UI uses (one write path).
- **Priority posture:** **Not a sprint priority.** It is a **constant:** whenever we touch net mutate APIs, keep them CLI-clean; periodically ask “can we do this from the terminal yet?” / “can capture flow more efficiently?”
- **Includes eventually:** net mutate verbs on `mix flowspec` (or sibling); optional model bind (local/cloud) for NL parse; clarifying-question loop.
- Existing today: `mix flowspec intake.capture` (ops intake) — **not** factory-net mutate.

### Mobile (deferred track — do not block PDF/versions)

- Separate **mobile section** of the app: cards as surfaces, popups as overlays.
- Programmatic reuse of card/popup atoms; **do not** dual-mode the desktop net.
- Phase 2+ relative to Michael desk workflow (see project `WARP.md`).

---

## Priority tracks

Order is consulting-throughput first (SOHO). Re-rank only with explicit dialog.

| P | Track | Why now | Depends on |
|---|--------|---------|------------|
| **P0** | **Save / versions** (+ change log; Editor role in schema = Michael) | Safe iMod entry; workshop baseline; unlocks later share | Card chrome usable enough to edit |
| **P0** | **PDF projection** (factory \| line \| card) + zeros/placeholders as full-kit signal | External conversation weapon; pencil-away-from-screen cards | Abacus honesty; staff roll-up good enough; mode-aware people math |
| **P0** | **Line + net summary reports** (+ bulk card pencil pack) | Reed/Roger/Robert email weapon at line and factory scope; workshop handout | T2.1 card sheets live; line ⋮ entry |
| **P0-soon** | **Card ⋮ guided build** (add feeding / transport / related — not Grasshopper canvas) | Desk net authoring without visual graph editor; legal next moves from each card | Domain create+link verbs; adjacency rules grilled |
| **P1** | **Four M tables on PDF** (real rows when data exists; zeros when not) | Zeros teach gap; filled rows win acquire/place/contract fight | P0 PDF shell; progressive F-path data |
| **P1** | **CSV acquisition list** | Purchasing handoff (Roger / Flowspec app later) | Machine/material rows |
| **P2** | **Share / multi-editor surface** (Reader links, others edit) | Schema reserved in P0; **surface is v2** | Versions stable; real demand for second Editor |
| **P2** | **Mobile card section** | Floor/line lead phone — after desk PDF loop works | Stable card/popup atoms |
| **Constant** | **CLI-clean domain mutate → later NL/Whisper** | Efficiency for Michael as app stabilizes; not a gated sprint | Every net write goes through domain functions callable from CLI |

---

## Track briefs (thin claims — grill before thick build)

### T1 — Versions (implemented 2026-08-08 — table-copy milestones)

1. **Working copy** = live factory tables. **Milestone** = named `INSERT…SELECT` into `factory_version_*` twins.
2. UI: **Save version** + **Milestones** list + confirm **Restore** on factory show.
3. Restore auto-saves current as `Auto before restore · …` then replaces working copy (new ids OK).
4. Parity: `mix flowspec.versions.parity` + fail-closed on Save/Restore + dedicated test.
5. Change log rows on save/restore (`factory_change_log`).
6. No JSON system of record. No multi-editor UI yet.
7. Twin schema rule in `WARP.md` — same migration updates primary + version tables.

### T2 — PDF

1. One export pipeline: `scope` ∈ {factory, line, card} + section flags.
2. Same math as face abacus / staff mode roll-up — **no second staffing story**.
3. Expert layout: tables, numbers, structure; **zero tutorial copy**.
4. **Zeros are load-bearing:** empty abacus/4M/manpower cells stay visible — full-kit gap without a sermon.
5. Placeholder/sample structure when a section has never been touched — still printable for pencil capture off-screen.
6. Print one card or one line on demand from the net UI.

### T2.1 — Pencil sheet slice 1 (locked 2026-08-11)

**First ship:** single-card **pencil sheet** (not factory pack, not line multi-card).

**Entry chrome (net UI):**
- **Card ⋮:** header-right cluster order `P · M · G · ● · ⋮` (menu after andon; does not replace status).
- **Line ⋮:** immediately after line title, **before** spine chips (`Frame Line  ⋮` then path).
- Line menu print deferred; card Print is the slice.

**Render path:** print-ready **HTML** page → browser Print dialog (print paper **or** Save as PDF). No second layout engine in v1. Working document: Numbers-like tables, shaded header rows, bold section labels, tabular numbers — **not** a screenshot of the LiveView card.

**Document character / density:**
- **Empty cells** for missing scalars (`—` / `0` columns stay).
- **Known lists:** real rows + **1 trailing blank row** for paper add.
- **Four M / catalogs not built:** header + columns + **3 blank rows** (structure teaches).
- **Notes:** short strip under **each** major block above it — label `Notes:` + blank ruled space (not one giant end-only essay unless section has nothing else).
- **Version line:** show current **milestone name** when one exists; else working-copy wording.

**Page packing (multi-card / line / factory):** **deferred** — learn from real card sheets first (open Q2).

**Kinds in slice 1 (desk iMod map):**
| Product language | Model |
|---|---|
| Work cell / station | `kind: work_cell` |
| Feeding | `kind: queue`, `queue_role: feeding_buffer` |
| Storage | `kind: queue`, `queue_role: storage_lot` (+ **storage group** UI card when `storage_group` collapses lots) |
| Bypass | `bypass_allowed` (and passthrough row on storage-group card) — sheet must surface bypass/passthrough, not invent a fifth `kind` |

**Out of slice 1:** supplier, transport pencil sheets (same ⋮ shell later); factory/line packed PDFs; Chromic/headless one-click file without browser Print.

**work_cell sheet sections (order):** header (factory · line · station · seq · date · version · P/M/G) → Abacus table → Notes strip → Steps (+ 1 blank) → Notes strip → Manpower (station) → Notes strip → Four M shells (3 blank rows each) → Notes strip.

**queue / feeding / storage sheet (thinner):** header → role · slots · group · location → bypass/passthrough if applicable → members (group) or feed/hold links → Notes strips under blocks.

**Acceptance (slice 1):**
1. ⋮ on work_cell + queue cards (+ storage group chrome) opens menu with **Print pencil sheet**.
2. Sheet opens print-ready; ⌘P works; empty nets still print with zeros/blanks.
3. Same abacus/staff numbers as face where data exists — no second math.
4. No tutorial prose on the page.

**Shipped 2026-08-11:** work_cell + queue (feeding/storage) + storage-group pencil sheets; card ⋮ print. Supplier/transport sheets still open.

### T2.2 — Line + net summary reports (next — grill 2026-08-11)

**Intent (provisional until grilled):** Line and factory (net) each get:
1. **Summary report** — expert tables: roll-up abacus / manpower / Four M / commitment vs can; zeros load-bearing; no tutorial prose.
2. **Bulk pencil pack** — one print job that includes the **same card pencil sheets** already built (work_cell, queue, storage group, …), scoped to that line or whole net.

**Entry points (intent):**
- **Line ⋮** after line title, before spine — Summary · Print all card sheets (pack) · later line build verbs.
- **Net / factory** — factory chrome (near Save version / Milestones or net-level ⋮) — Summary · Print all card sheets for factory.

**Not yet locked:** single long HTML vs multi-section with page breaks; whether bulk pack is “summary first then every card” or pack-only menu item; supplier/transport inclusion before their sheets exist.

**Depends on:** T2.1 card sheets (done for primary kinds); shared StationMath / print CSS.

### T6 — Card ⋮ guided build / adjacency navigation (soon — not this slice)

**Product move (2026-08-11 dialog):** Card ⋮ is the **local build menu**, not only export. From a card, guided actions like **add feeding**, **add transport**, (later link/relate) — **built-in navigation** that grows the net without a Grasshopper-style free canvas.

**Why:** Users stay on the scannable card spine; legal next moves teach flow structure; one write path (menu → domain create + link).

**Priority:** **Soon** after line/net reports — importance rising as ⋮ proves itself. Do **not** silent-default adjacency.

**Thin claims (pre-grill):**
1. ⋮ stays a short menu: print · allowed adds · destructive last — not a junk drawer.
2. Each add verb has **direction** (upstream feed vs downstream hold, etc.) encoded in the label.
3. Line ⋮ owns line-level adds; card ⋮ owns **from-this-node** adjacency.
4. Storage-group ⋮ vs member lot ⋮ ownership for “add lot” must be explicit before code.
5. No canvas/graph editor track — adjacency menus are the v1 authoring path.

**Open before implement:** adjacency table (from_kind → actions); first verb to ship (candidate: add feeding before/into this station).

### T3 — Share (v2 surface)

1. **v1:** single Editor (Michael); partners via print + live present; no invite UI required.
2. **v2:** share a version (or baseline) with Reader (and later second Editor); change log already exists from T1.
3. Intimate: revoke, no org-tree, no SSO required at first share surface.

### T4 — CLI / Whisper (constant, progressive)

1. **Discipline now:** all net mutations live in domain modules callable without LiveView.
2. **When stable:** extend `mix flowspec` with net verbs (card/line/project upsert, abacus set, etc.) — operator-readable.
3. **Later efficiency:** STT/Whisper → text file or stdin → same CLI; NL layer may ask clarifying questions before apply.
4. Optional model router (local/cloud) only when NL parse exists; SOHO-cheap default.
5. Prefer apply onto versioned net so bad parses undo.
6. Revisit whenever a desk workflow feels click-heavy: “can CLI do this yet?”

### T5 — Mobile section (later)

1. Routes under a mobile shell; desktop `factory/show` untouched in layout contract.
2. Card face + popup overlays only; no full net pan/zoom requirement v1 unless trivial.

---

## Explicit non-goals (for these tracks)

- Spoon-fed PDF narrative for beginners as primary artifact
- Utilization % / person scoreboards on PDF
- Hiding zeros to make the plan look “ready”
- Multi-editor collab UI in v1 (schema only)
- Enterprise RBAC, SSO, multi-tenant orgs in first share surface
- Making desktop net “also mobile” via one responsive stylesheet
- Building a Whisper product before domain+CLI verbs exist
- Dual entry: email notes that never hit the net

---

## Open questions (do not silent-default)

1. Versions v1: manual Save only vs quiet auto-draft every N minutes while Michael presents live?
2. Line/net bulk pack: summary-then-all-cards one document, or two menu actions (Summary | Pack cards only)? Page break policy per card?
3. First CLI verbs when we crack them open: spin up project/line shell, or mutate existing iMod stations?
4. Card ⋮ adjacency: first ship verb and direction labels (feeding / transport / …)?
5. Unified card header component: **wait** until trailing clusters stabilize (supplier/transport ⋮ + build verbs) — do not extract early.

---

## Changelog

| Date | Note |
|------|------|
| 2026-08-06 | Created from PDF / share / whisper dialog. Q1–Q3 first pass. |
| 2026-08-06 | Q1–Q3 clarified: zeros = full-kit signal + pencil cards; Michael sole Editor v1, multi-edit surface v2; Whisper/CLI = constant efficiency path not near sprint. |
| 2026-08-08 | Versions implemented: table-copy milestones, parity Mix task, Save/Restore UI, WARP twin rule. |
| 2026-08-11 | PDF T2.1 locked: single-card pencil sheet first; card ⋮ after andon; line ⋮ after title; HTML→browser Print; kind focus work_cell + feeding/storage/bypass; notes strip under each block; version name when milestone exists; packing deferred. |
| 2026-08-11 | T2.1 shipped work_cell + queue + storage-group pencil. T2.2 line/net summary + bulk card pack next. T6 card ⋮ guided build (add feeding/transport) soon — not canvas. Unified header deferred. |

*When a track starts: write thin phase claims → conflict check → implement one slice → Michael uses on iMod VA.*
