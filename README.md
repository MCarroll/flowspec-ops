# FlowspecOps

Operational home for FlowSpec operations, including R&D/CAD work, factory consulting, and database app work.

Domain model identity: `ops.flowspec.co`

Core decision lenses applied across this app:
- Rules of Flow
- PFEP (Plan For Every Part)
- Throughput Accounting

## Intake Standard Work (Agent Rule)

- Project rules live in `WARP.md`.
- Intake is single-entry from Warp terminal (no dual entry).
- Agents must write one unified payload to app records and local mirror artifacts.
- Required intake fields: `client_ref`, `action_title`, `commentary`, `next_action`, `status`, `priority_rank`.

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start with `bin/server start` (tmux-managed)
  * Or run directly with `mix phx.server` / `iex -S mix phx.server`

Now you can visit [`localhost:4008`](http://localhost:4008) from your browser.

## Dev Server Management (tmux)

- `bin/server start` — Start in tmux session `flowspec-ops`
- `bin/server stop` — Stop the server
- `bin/server restart` — Restart
- `bin/server status` — Check if running
- `bin/server logs` — Attach to output (Ctrl+B, D to detach)

## CLI Entry Point

Use `mix flowspec` to interact with domain services locally:

- `mix flowspec ping`
- `mix flowspec status`
- `mix flowspec order.create ORDER_REF`
- `mix flowspec queue.transition ORDER_REF TO_STATUS`
- `mix flowspec intake.capture --client-ref REF --client-name NAME --contact-name NAME --contact-email EMAIL --task "TITLE|STATUS|COMMENTARY|NEXT_ACTION|PRIORITY"`

Example (single command, multiple tasks):

`mix flowspec intake.capture --client-ref HHCO --client-name "Higher Health" --contact-name "Max" --contact-email "max@higherhealth.com" --task "Email CaliJane2 invite|blocked|Invite is blocked pending visuals|Send invite after attachments are ready|1" --task "Create Graffle company/brand wiring diagram|active|Needed for onboarding context email|Export diagram PDF for attachment|2" --task "Create 3D press mold drawing|active|Technical visual for client packet|Export latest drawing revision|3"`

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
