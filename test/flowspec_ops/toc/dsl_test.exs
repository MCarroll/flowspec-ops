defmodule FlowspecOps.TOC.DSLTest do
  use ExUnit.Case, async: true

  alias FlowspecOps.TOC.DSL

  @dsl """
  cloud cc1: a1 b1 c1 d1 d1p
  node a1: CommonObjective "Reap the benefits of a data center";
  node b1: Need "Belief that open dialog will facilitate the project being adopted";
  node c1: Need "Belief that open dialog will block the project";
  node d1: Want "Invite cooperative dialog with communities";
  node d1p: Want "Manipulate local politicians to bypass public comment";
  node ude1: UndesirableEffect "Public distrusts the AI elite";
  node ie1: IntermediateEffect "Pressure to accelerate approval";
  number ude1: 1.0
  number ie1: 1.1
  edge a1 -> b1
  edge a1 -> c1
  edge b1 -> d1
  edge c1 -> d1p
  edge ie1 -> ude1
  edge d1p -> ie1
  """

  test "parse reads nodes, edges, clouds and stored numbers" do
    g = DSL.parse(@dsl)
    assert length(g.nodes) == 7
    assert length(g.edges) == 6
    assert hd(g.clouds).members == ~w(a1 b1 c1 d1 d1p)
    assert g.numbers["ude1"] == "1.0"
  end

  test "layout puts roots at the bottom and climbs upward" do
    g = DSL.layout(DSL.parse(@dsl))
    by_id = Map.new(g.nodes, &{&1.id, &1})

    # a1 is a root (no incoming) -> bottom; ude1 is the deepest target -> top
    assert by_id["ude1"].y < by_id["ie1"].y
    assert by_id["ie1"].y < by_id["a1"].y

    # stored numbers win; cloud internals keep letters
    assert by_id["ude1"].number == "1.0"
    assert by_id["ie1"].number == "1.1"
    assert by_id["a1"].letter == "A"
    assert by_id["d1"].letter == "D"
    assert by_id["d1p"].letter == "D'"
    assert by_id["ude1"].letter == ""
  end

  test "every edge carries an SVG path" do
    g = DSL.layout(DSL.parse(@dsl))
    assert Enum.all?(g.edges, &(&1.path =~ ~r/^M -?[\d.]+ -?[\d.]+/))
    assert Enum.all?(g.back_edges, &(&1.path =~ ~r/^M -?[\d.]+ -?[\d.]+/))
  end

  test "forward edges are straight when the way is clear" do
    g = DSL.layout(DSL.parse("node a: Given \"A\";\nnode b: Given \"B\";\nedge a -> b"))
    assert hd(g.edges).path =~ ~r/^M -?[\d.]+ -?[\d.]+ L -?[\d.]+ -?[\d.]+$/
  end

  test "back-edges arc (curve), never straight" do
    g =
      DSL.layout(
        DSL.parse("""
        node a: Given "A";
        node b: Given "B";
        node c: Given "C";
        edge a -> b
        edge b -> c
        edge c -> a
        """)
      )

    assert g.back_edges != []
    assert length(g.edges) == 2
    assert Enum.all?(g.back_edges, &String.contains?(&1.path, "Q"))
  end

  test "no edge path crosses a cloud rect (cloud-internal edges exempt by design)" do
    g = DSL.layout(DSL.parse(@dsl))
    cloud = hd(g.clouds)
    rect = cloud_rect(g.nodes, cloud)
    members = MapSet.new(cloud.members)

    Enum.each(g.edges ++ g.back_edges, fn e ->
      # an edge touching a cloud member legitimately attaches to / leaves the cloud
      if not (MapSet.member?(members, e.from) or MapSet.member?(members, e.to)) do
        refute crosses?(e.path, rect), "edge #{e.from}->#{e.to} crosses the cloud: #{e.path}"
      end
    end)
  end

  test "edges to unknown ids are dropped, not crashed on" do
    g = DSL.layout(DSL.parse("node x: Given \"G\";\nedge x -> ghost"))
    assert g.edges == []
    assert length(g.nodes) == 1
  end

  # --- helpers: mirror the router's geometry so the test can check the rule ---

  defp cloud_rect(nodes, cloud) do
    mem = Enum.filter(nodes, &(&1.id in cloud.members))
    x1 = Enum.min(Enum.map(mem, & &1.x)) - 16
    y1 = Enum.min(Enum.map(mem, & &1.y)) - 16
    x2 = Enum.max(Enum.map(mem, & &1.x)) + 256
    y2 = Enum.max(Enum.map(mem, & &1.y)) + DSL.box_height("x") + 16
    {x1, y1, x2, y2}
  end

  # Sample the path's polyline segments (L only — arcs are exempt: they curve
  # above the tree, not through the cloud).
  defp crosses?(path, {rx1, ry1, rx2, ry2}) do
    pts =
      Regex.scan(~r/([\d.]+) ([\d.]+)/, path)
      |> Enum.map(fn [_, x, y] -> {parse_num(x), parse_num(y)} end)

    # Arcs are exempt: they curve above the tree, not through the cloud.
    if String.contains?(path, "Q") do
      false
    else
      Enum.chunk_every(pts, 2, 1, :discard)
      |> Enum.any?(fn [{x1, y1}, {x2, y2}] -> seg_crosses?(x1, y1, x2, y2, rx1, ry1, rx2, ry2) end)
    end
  end

  defp parse_num(s) do
    case Float.parse(s) do
      {f, _} -> f
      :error -> String.to_integer(s)
    end
  end

  defp seg_crosses?(x1, y1, x2, y2, rx1, ry1, rx2, ry2) do
    dx = x2 - x1
    dy = y2 - y1
    t0 = 0.0
    t1 = 1.0

    clip = fn p, q, {t0, t1} ->
      if p == 0.0 do
        if q < 0.0, do: :miss, else: {:ok, {t0, t1}}
      else
        t = q / p

        if p < 0.0 do
          if t > t1, do: :miss, else: {:ok, {max(t0, t), t1}}
        else
          if t < t0, do: :miss, else: {:ok, {t0, min(t1, t)}}
        end
      end
    end

    with {:ok, {t0, t1}} <- clip.(-dx, x1 - rx1, {t0, t1}),
         {:ok, {t0, t1}} <- clip.(dx, rx2 - x1, {t0, t1}),
         {:ok, {t0, t1}} <- clip.(-dy, y1 - ry1, {t0, t1}),
         {:ok, {t0, t1}} <- clip.(dy, ry2 - y1, {t0, t1}) do
      t0 < t1
    else
      _ -> false
    end
  end
end
