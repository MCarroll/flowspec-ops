# Flowspec Ops Project Rules

## Product Identity
- Domain model identity: `ops.flowspec.co`
- This app is the operational home for FlowSpec operations, R&D/CAD work, factory consulting, and database app work.

## Decision Lenses (Always On)
- Rules of Flow
- PFEP (Plan For Every Part)
- Throughput Accounting

## Collaboration Stance (TWI)
We build process together. This is a Training Within Industry house, not a fragile-ego house.

Required agent behavior:
1. Dialog until mutual understanding — do not sulk, apologize theatrically, or collapse when corrected.
2. Corrections are process data. Restate what you heard, adjust the model, continue.
3. Prefer calm professional partnership over people-pleasing or defensive over-explaining.
4. When unclear, ask a sharp question. When clear, implement or propose the next concrete step.
5. "No" means stop that path and clarify — not emotional withdrawal.

## UI Priority (Phase 1)
- Primary user: Michael (desk workflow, deep CAD context).
- Optimize for desktop capture and processing speed first.
- Mobile/floor UX is phase 2+, not a phase 1 blocker.

## Unified Intake Rule (No Dual System)
When capturing new work, there is exactly one intake action from the terminal. Agents must treat that one action as the source of truth and project it into all required destinations.

Required behavior:
1. Single-entry capture: the user unloads thoughts once in Warp.
2. Unified write path: agent writes to application intake/domain records (primary system of record).
3. Local mirror creation: agent creates/updates corresponding local Mac-side working artifacts from the same payload (no second manual entry by user).
4. Shared identifier: every captured item gets one canonical id used across app records and local artifacts.
5. Next action required: each intake item must include a clearly stated next action.
6. Blocked/waiting visibility: each intake item must carry a status (`active`, `blocked`, `waiting`, `done`) for counters and board views.

## Agent Onboarding / Intake Contract
For every intake operation, agents must capture at least:
- `client_ref` (or `inbox` when not yet assigned)
- `action_title`
- `commentary`
- `next_action`
- `status` (`active|blocked|waiting|done`)
- `priority_rank` (sortable integer)

Agents should reject incomplete intake payloads and ask for missing required fields in the same turn whenever possible.

When intake is for CAD/manufacturing work, agents must also capture:
- `project_ref`
- `master_assembly`
- `intake_group`
- `part_name`

For CAD/manufacturing intake interactions, agents should guide toward this one-command structure:
- `mix flowspec intake.capture --client-ref ... --client-name ... --project-ref ... --master-assembly ... --intake-group ... --part-name ... --action-title ... --status ... --commentary ... --next-action ... --priority-rank ...`

## Data Discipline
- Avoid parallel ad-hoc lists that diverge from the app model.
- Never require user double-entry between terminal notes and app data.
- Keep command and model names operator-readable and flow-oriented (no cost-world naming).

## Code Consistency (Directory Rule)
- Keep implementation patterns consistent with Phoenix conventions already in this repo.
- Prefer small, incremental changes over broad rewrites.
- New behavior should be added through domain modules + adapters (LiveView/API/CLI), not duplicated logic.
- Keep naming consistent with this domain model (`ops.flowspec.co`, client/contact/task vocabulary).
- Before handoff, validate with compile and relevant local checks.

## Orchestration Defaults for This Directory
- For coding/build tasks, orchestrator should delegate to codex builder agent by default.
- Preferred builder model: `gpt-5-2-codex-low`.
- Use lightweight review/escalation only when needed for risk or ambiguity.
