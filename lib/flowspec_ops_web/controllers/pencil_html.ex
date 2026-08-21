defmodule FlowspecOpsWeb.PencilHTML do
  use FlowspecOpsWeb, :html

  alias FlowspecOps.Factories.StationMath

  embed_templates "pencil_html/*"

  def format_duration(m), do: StationMath.format_duration_minutes(m)
  def format_dwm(v), do: StationMath.format_dwm(v)
  def format_rate(v), do: StationMath.format_rate(v)
  def format_gap(v), do: StationMath.format_gap(v)
  def yes_dash(v), do: StationMath.yes_dash(v)
  def dash_or(v), do: StationMath.dash_or(v)

  def version_label(nil), do: "Working copy"
  def version_label(%{name: name}) when is_binary(name) and name != "", do: name
  def version_label(_), do: "Working copy"

  def format_printed_at(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")
  end

  def format_printed_at(_), do: "—"

  def queue_role_label(:storage_lot), do: "Storage lot"
  def queue_role_label(:feeding_buffer), do: "Feeding buffer"
  def queue_role_label(:queue), do: "Queue"
  def queue_role_label(_), do: "Queue"

def print_css do
    """
    :root { color-scheme: light; }
    * { box-sizing: border-box; }
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      min-height: auto;
      overflow: visible;
      background: #fff;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
      font-size: 11pt;
      line-height: 1.35;
      color: #111;
    }
    .toolbar {
      display: flex;
      gap: 0.5rem;
      align-items: center;
      justify-content: space-between;
      padding: 0.6rem 0.9rem;
      border-bottom: 1px solid #ccc;
      background: #f4f4f5;
      position: sticky;
      top: 0;
      z-index: 20;
    }
    .toolbar button, .toolbar a {
      font: inherit;
      font-size: 10pt;
      padding: 0.35rem 0.7rem;
      border: 1px solid #999;
      border-radius: 4px;
      background: #fff;
      color: #111;
      text-decoration: none;
      cursor: pointer;
    }
    .toolbar .hint { font-size: 9pt; color: #555; }
    .sheet {
      /* Screen preview ≈ Letter portrait content width */
      width: 100%;
      max-width: 7.5in;
      margin: 0 auto;
      padding: 0.55in 0.5in 0.85in;
    }
    h1 {
      margin: 0 0 0.15rem;
      font-size: 16pt;
      font-weight: 700;
      letter-spacing: 0.01em;
    }
    .meta {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0.15rem 1rem;
      margin: 0.35rem 0 0.75rem;
      font-size: 9.5pt;
    }
    .meta .k {
      color: #444;
      font-weight: 600;
      text-transform: uppercase;
      font-size: 8pt;
      letter-spacing: 0.04em;
    }
    .meta .v { font-variant-numeric: tabular-nums; }
    .gates {
      display: flex;
      flex-wrap: wrap;
      gap: 0.75rem;
      font-size: 9.5pt;
      font-variant-numeric: tabular-nums;
    }
    .gates strong { font-weight: 700; }
    h2 {
      margin: 0.85rem 0 0.3rem;
      font-size: 10pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.06em;
      border-bottom: 1.5px solid #111;
      padding-bottom: 0.15rem;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 9.5pt;
      font-variant-numeric: tabular-nums;
    }
    th, td {
      border: 1px solid #bbb;
      padding: 0.28rem 0.35rem;
      vertical-align: top;
      text-align: left;
    }
    th {
      background: #e4e4e7;
      font-weight: 700;
      font-size: 8pt;
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }
    td.num, th.num { text-align: right; }
    td.blank { height: 1.15rem; }
    .notes {
      margin: 0.35rem 0 0.15rem;
      border: 1px solid #ccc;
      min-height: 2.4rem;
      padding: 0.2rem 0.35rem;
    }
    .notes-label {
      font-size: 8pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: #444;
      margin-bottom: 0.1rem;
    }
    .notes-lines {
      border-top: 1px solid #ddd;
      min-height: 1.6rem;
    }
    .fourm-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0.55rem 0.75rem;
    }
    .fourm-grid h3 {
      margin: 0 0 0.2rem;
      font-size: 9pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
/* Screen-only page cue; real page # is print footer / @page */
    .print-footer {
      display: none;
    }
/* Default print geometry: US Letter portrait (8.5×11). Browsers may still
       remember last dialog choice; user can flip to landscape without data loss. */
    @page {
      size: letter portrait;
      margin: 0.5in 0.55in 0.7in 0.55in;
      @bottom-right {
        content: counter(page);
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
        font-size: 9pt;
        color: #333;
      }
    }
    @media print {
      .toolbar { display: none !important; }
      html, body {
        width: auto !important;
        height: auto !important;
        min-height: 0 !important;
        overflow: visible !important;
        background: #fff !important;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
      }
      .sheet {
        width: auto !important;
        max-width: 7.4in !important;
        margin: 0 auto !important;
        padding: 0 0 0.35in 0 !important;
      }
      /* Keep content portrait-shaped so engines prefer portrait over landscape */
      .fourm-grid {
        grid-template-columns: 1fr;
      }
      table { page-break-inside: auto; }
      tr, h2 { page-break-inside: avoid; }
      body { font-size: 10pt; }
      a { color: inherit; text-decoration: none; }
      /* Fallback page number (Safari / some WebKit): repeats each printed page */
      .print-footer {
        display: block;
        position: fixed;
        right: 0;
        bottom: 0;
        font-size: 9pt;
        color: #333;
        font-variant-numeric: tabular-nums;
      }
      .print-footer .page-num::after {
        content: counter(page);
      }
    }
    """
  end
end
