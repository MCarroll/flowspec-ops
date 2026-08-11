defmodule FlowspecOps.Factories.StationMath do
  @moduledoc """
  Shared station timing and rate math for the net face and pencil sheet.

  One staffing / abacus story — LiveView and print both call this module.
  Workday defaults: node_design_spec §20 (360 productive minutes / day).
  """

  alias FlowspecOps.Factories.FactoryNodeStep

  # Standard paid shift 8h; OH = breaks 30 + 3S 30 + lunch 45 + standup 15 = 120.
  @standard_shift_min 480
  @oh_breaks_min 30
  @oh_cleanup_3s_min 30
  @oh_lunch_min 45
  @oh_standup_min 15
  @standard_productive_min @standard_shift_min - @oh_breaks_min - @oh_cleanup_3s_min -
                            @oh_lunch_min - @oh_standup_min
  @workdays_per_week 5
  @workdays_per_month 20

  def standard_productive_min, do: @standard_productive_min

  def required_weekly_rate(%{target_qty: qty, window_days: days})
      when is_integer(qty) and is_integer(days) and days > 0 do
    Float.round(qty * 7.0 / days, 1)
  end

  def required_weekly_rate(_), do: nil

  def station_dwm_rates(cycle_min) when is_integer(cycle_min) and cycle_min > 0 do
    d = Float.round(@standard_productive_min / cycle_min, 1)
    w = Float.round(d * @workdays_per_week, 1)
    m = Float.round(d * @workdays_per_month, 1)
    {d, w, m}
  end

  def station_dwm_rates(_), do: {nil, nil, nil}

  def step_stat(step) do
    qty = step.qty_per_unit
    each = step.minutes_each || step.estimated_minutes

    content =
      cond do
        is_integer(qty) and is_integer(step.minutes_each) -> qty * step.minutes_each
        is_integer(step.estimated_minutes) -> step.estimated_minutes
        true -> nil
      end

    %{
      step: step,
      content: content,
      stream: FactoryNodeStep.process_minutes(step),
      people: step.people,
      qty: qty,
      each: each
    }
  end

  # Returns {ea_parallel, ea_phased, designed_crew, peak_phase_people}
  def step_timing_summary(steps, step_stats) do
    stats_by_id = Map.new(step_stats, fn s -> {s.step.id, s} end)
    parent = parallel_parent_map(steps)

    groups =
      steps
      |> Enum.group_by(fn s -> find_root(parent, s.id) end)
      |> Map.values()

    group_streams =
      Enum.map(groups, fn group_steps ->
        streams =
          group_steps
          |> Enum.map(fn s -> stats_by_id[s.id] && stats_by_id[s.id].stream end)
          |> Enum.reject(&is_nil/1)

        people =
          group_steps
          |> Enum.map(fn s -> stats_by_id[s.id] && stats_by_id[s.id].people end)
          |> Enum.reject(&is_nil/1)
          |> Enum.sum()

        stream =
          case streams do
            [] -> nil
            list -> Enum.max(list)
          end

        %{stream: stream, people: people}
      end)

    ea_par =
      group_streams
      |> Enum.map(& &1.stream)
      |> Enum.reject(&is_nil/1)
      |> case do
        [] -> 0
        list -> Enum.sum(list)
      end

    ea_phase =
      step_stats
      |> Enum.map(& &1.stream)
      |> Enum.reject(&is_nil/1)
      |> case do
        [] -> 0
        list -> Enum.sum(list)
      end

    phase_people =
      group_streams
      |> Enum.map(& &1.people)
      |> Enum.reject(&(&1 == 0))

    crew =
      case phase_people do
        [] -> nil
        list -> Enum.sum(list)
      end

    peak_phase =
      case phase_people do
        [] -> nil
        list -> Enum.max(list)
      end

    {ea_par, ea_phase, crew, peak_phase}
  end

  def parallel_parent_map(steps) do
    parent = Map.new(steps, fn s -> {s.id, s.id} end)

    Enum.reduce(steps, parent, fn s, acc ->
      case s.parallel_with_step_id do
        nil -> acc
        other_id -> union_ids(acc, s.id, other_id)
      end
    end)
  end

  def find_root(parent, id) do
    case Map.get(parent, id, id) do
      ^id -> id
      other -> find_root(parent, other)
    end
  end

  def union_ids(parent, a, b) do
    ra = find_root(parent, a)
    rb = find_root(parent, b)
    if ra == rb, do: parent, else: Map.put(parent, ra, rb)
  end

  @doc """
  Projection map for work_cell pencil sheet (and any consumer that needs the same numbers).
  """
  def work_cell_sheet(factory, node) do
    steps = Enum.sort_by(node.steps || [], & &1.position)
    step_stats = Enum.map(steps, &step_stat/1)
    {ea_par, ea_phase, crew, peak_phase} = step_timing_summary(steps, step_stats)
    slots = node.slots

    batch_cycle_min =
      cond do
        is_integer(slots) and slots > 0 and is_integer(ea_par) and ea_par > 0 ->
          slots * ea_par

        true ->
          nil
      end

    {rate_d, rate_w, rate_m} = station_dwm_rates(if(ea_par > 0, do: ea_par, else: nil))
    need_wk = required_weekly_rate(factory)

    rate_gap =
      if is_float(need_wk) and is_float(rate_w) do
        Float.round(need_wk - rate_w, 1)
      else
        nil
      end

    %{
      steps: steps,
      step_stats: step_stats,
      ea_parallel: if(ea_par > 0, do: ea_par, else: nil),
      ea_phased: if(ea_phase > 0, do: ea_phase, else: nil),
      batch_cycle_min: batch_cycle_min,
      slots: slots,
      crew: crew,
      peak_phase: peak_phase,
      rate_d: rate_d,
      rate_w: rate_w,
      rate_m: rate_m,
      need_wk: need_wk,
      rate_gap: rate_gap,
      rate_gap_short?: is_float(rate_gap) and rate_gap > 0,
      product_ready: node.product_ready == true,
      method_instruction: node.method_instruction == true,
      gate: node.gate == true,
      bypass_allowed: node.bypass_allowed == true
    }
  end

  def format_duration_minutes(m) when is_integer(m) and m > 0 do
    hours = div(m, 60)
    mins = rem(m, 60)

    cond do
      hours > 0 and mins > 0 -> "#{hours}h #{mins}m"
      hours > 0 -> "#{hours}h"
      true -> "#{mins}m"
    end
  end

  def format_duration_minutes(_), do: "—"

  def format_dwm(nil), do: "—"
  def format_dwm(n) when is_float(n), do: :erlang.float_to_binary(n, decimals: 1)
  def format_dwm(n) when is_integer(n), do: Integer.to_string(n)

  def format_rate(nil), do: "—"
  def format_rate(n) when is_float(n), do: :erlang.float_to_binary(n, decimals: 1)
  def format_rate(n) when is_integer(n), do: Integer.to_string(n)

  def format_gap(nil), do: "—"

  def format_gap(gap) when is_float(gap) or is_integer(gap) do
    cond do
      gap > 0 -> format_rate(gap)
      gap < 0 -> "+#{format_rate(abs(gap))}"
      true -> "ok"
    end
  end

  def dash_or(nil), do: "—"
  def dash_or(""), do: "—"
  def dash_or(v), do: v

  def yes_dash(true), do: "Y"
  def yes_dash(_), do: "—"
end
