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
end
