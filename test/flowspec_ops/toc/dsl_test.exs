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

  test "labelless node parses (AndJunctior); numbering passes through it" do
    g =
      DSL.layout(
        DSL.parse("""
        node ude1: UndesirableEffect "UDE";
        node and1: AndJunctior;
        node ie1: IntermediateEffect "Harm";
        node ie2: IntermediateEffect "Benefit elsewhere";
        edge ie1 -> and1
        edge ie2 -> and1
        edge and1 -> ude1
        """)
      )

    by_id = Map.new(g.nodes, &{&1.id, &1})

    # the labelless junctor survives parsing with the id as its label
    assert by_id["and1"].label == "and1"
    # its two inbound IEs still belong to the UDE's branch
    assert by_id["ie1"].number == "1.1"
    assert by_id["ie2"].number == "1.2"
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

  test "cloud lays out on its side: A left, B/C middle, D/D' right" do
    graph =
      DSL.layout(
        DSL.parse("""
        cloud cc1: a1 b1 c1 d1 d1p
        node a1: CommonObjective "Reap the benefits";
        node b1: Need "Open dialog facilitates adoption";
        node c1: Need "Open dialog blocks adoption";
        node d1: Want "Invite cooperative dialog";
        node d1p: Want "Manipulate politicians";
        edge a1 -> b1
        edge a1 -> c1
        edge b1 -> d1
        edge c1 -> d1p
        """)
      )

    xpos = Map.new(graph.nodes, &{&1.id, &1.x})
    # columns strictly left to right: A < {B, C} < {D, D'}
    assert xpos["a1"] < xpos["b1"]
    assert xpos["a1"] < xpos["c1"]
    assert xpos["b1"] < xpos["d1"]
    assert xpos["b1"] < xpos["d1p"]
    assert xpos["c1"] < xpos["d1"]
    assert xpos["c1"] < xpos["d1p"]

    # D above D' in the right column
    ypos = Map.new(graph.nodes, &{&1.id, &1.y})
    assert ypos["d1"] < ypos["d1p"]
  end

  test "assume statements parse into edge-attached assumptions" do
    parsed =
      DSL.parse("""
      node a1: CommonObjective "A";
      node b1: Need "B";
      edge a1 -> b1
      assume a1->b1: "People trust open dialog"
      """)

    assert [%{from: "a1", to: "b1", text: "People trust open dialog"}] = parsed.assumptions
    assert DSL.layout(parsed).assumptions == parsed.assumptions
  end

  test "pin and inject statements parse and survive layout" do
    parsed =
      DSL.parse("""
      node ude1: UndesirableEffect "X";
      pin 4@2
      inject 3
      inject 7
      """)

    assert parsed.pins == [%{cloud_id: 4, version: 2}]
    assert parsed.injections == [3, 7]

    layout = DSL.layout(parsed)
    assert layout.pins == parsed.pins
    assert layout.injections == parsed.injections
  end

  test "cloud diamond: B and D share top row, C and D' share bottom row, A centered" do
    graph =
      DSL.layout(
        DSL.parse("""
        cloud cc1: a1 b1 c1 d1 d1p
        node a1: CommonObjective "Reap the benefits";
        node b1: Need "Open dialog facilitates adoption";
        node c1: Need "Open dialog blocks adoption";
        node d1: Want "Invite cooperative dialog";
        node d1p: Want "Manipulate politicians";
        edge a1 -> b1
        edge a1 -> c1
        edge b1 -> d1
        edge c1 -> d1p
        """)
      )

    pos = Map.new(graph.nodes, &{&1.id, %{x: &1.x, y: &1.y, h: DSL.box_height(&1.label)}})

    # ROW ALIGNMENT: B top == D top; C top == D' top
    assert pos["b1"].y == pos["d1"].y
    assert pos["c1"].y == pos["d1p"].y

    # A in its own column (left of both), centered on the diamond's extent
    assert pos["a1"].x < pos["b1"].x
    assert pos["a1"].x < pos["d1"].x
    a_mid = pos["a1"].y + div(pos["a1"].h, 2)
    diamond_top = pos["b1"].y
    diamond_bottom = pos["c1"].y + pos["c1"].h
    assert abs(a_mid - div(diamond_top + diamond_bottom, 2)) <= 2
  end

  test "tension statement parses and survives layout" do
    parsed =
      DSL.parse("""
      node a1: CommonObjective "A";
      tension "I need to build AI data centers, and public resentment grows"
      """)

    assert parsed.tension == "I need to build AI data centers, and public resentment grows"
    assert DSL.layout(parsed).tension == parsed.tension
  end

  test "empty cloud shows all five canonical boxes; filled members take their slots" do
    # only A and one Need exist — B-empty, C, D, D' must still render
    graph =
      DSL.layout(
        DSL.parse("""
        cloud cc1: a1 b1
        node a1: CommonObjective "Shared goal";
        node b1: Need "Build the thing";
        """)
      )

    placeholders = Enum.filter(graph.nodes, &Map.get(&1, :placeholder))
    assert length(placeholders) == 3
    assert Enum.map(placeholders, & &1.letter) |> Enum.sort() == ["C", "D", "D'"]

    # placeholders sit in their canonical columns (A col 0, B/C col 1, D/D' col 2)
    xpos = Map.new(graph.nodes, &{&1.letter || &1.id, &1.x})
    assert xpos["A"] < xpos["C"]
    assert xpos["C"] < xpos["D"]
  end

  test "fully empty cloud still renders five placeholder boxes" do
    graph =
      DSL.layout(
        DSL.parse("""
        cloud cc1:
        """)
      )

    placeholders = Enum.filter(graph.nodes, &Map.get(&1, :placeholder))
    assert Enum.map(placeholders, & &1.letter) |> Enum.sort() == ["A", "B", "C", "D", "D'"]
  end
end
