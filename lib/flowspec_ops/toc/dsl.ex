defmodule FlowspecOps.TOC.DSL do
  @moduledoc """
  Parse the TOC DSL text into a graph and lay it out bottom-up for SVG rendering.

  DSL format (one statement per line, `;` optional):

      node ude1: UndesirableEffect "Sales revenue declining";
      node and1: AndJunctior;
      node g1: Given "Market is highly competitive";
      edge c1 -> ie2

  Node types: UndesirableEffect, IntermediateEffect, AndJunctior, Given,
  Changeable, CommonObjective, Need, Want, Conflict, Injection.
  """

  @node_w 240
  @pad 16
  @wrap_cols 24

  # Class -> (badge prefix, fill, stroke) for rendering.
  @colors %{
    "CommonObjective" => {"A", "#b2f2bb", "#2f9e44"},
    "Need" => {"B", "#ffe8cc", "#e8590c"},
    "Want" => {"D", "#fcc2d7", "#d6336c"},
    "Conflict" => {"", "#ffc9c9", "#c92a2a"},
    "IntermediateEffect" => {"IE", "#ffe3e3", "#e03131"},
    "UndesirableEffect" => {"UDE", "#fff0f0", "#e03131"},
    "Injection" => {"INJ", "#d0ebff", "#1971c2"},
    "Given" => {"GIVEN", "#d0ebff", "#1971c2"},
    "Changeable" => {"CHG", "#ffec99", "#f08c00"},
    "AndJunctior" => {"AND", "#212529", "#212529"}
  }

  def colors, do: @colors

  @doc "Parse DSL text into %{nodes: [%{id, type, label}], edges: [%{from, to}], clouds: [%{id, members}], numbers: %{id => \"1.13\"}}."
  def parse(dsl) when is_binary(dsl) do
    dsl
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.reduce(%{nodes: [], edges: [], clouds: [], numbers: %{}}, &parse_line/2)
  end

  defp parse_line("cloud " <> rest, acc) do
    # cloud cc1: a1 b1 c1 d1 d1p
    case Regex.run(~r/^(\w+)\s*:\s*([\w\s]+)$/, rest) do
      [_, id, members] ->
        %{acc | clouds: acc.clouds ++ [%{id: id, members: String.split(members)}]}

      _ ->
        acc
    end
  end

  defp parse_line("number " <> rest, acc) do
    # number ie8: 1.13
    case Regex.run(~r/^(\w+)\s*:\s*([\w.]+)\s*;?\s*$/, rest) do
      [_, id, num] ->
        %{acc | numbers: Map.put(acc.numbers, id, num)}

      _ ->
        acc
    end
  end

  defp parse_line("node " <> rest, acc) do
    # node id: Type "label";
    case Regex.run(~r/^(\w+)\s*:\s*(\w+)\s*(?:"([^"]*)")?\s*;?$/, rest) do
      [_, id, type, label] ->
        %{acc | nodes: acc.nodes ++ [%{id: id, type: type, label: label || id}]}

      _ ->
        acc
    end
  end

  defp parse_line("edge " <> rest, acc) do
    case Regex.run(~r/^(\w+)\s*->\s*(\w+)\s*;?$/, rest) do
      [_, from, to] -> %{acc | edges: acc.edges ++ [%{from: from, to: to}]}
      _ -> acc
    end
  end

  defp parse_line(_line, acc), do: acc

  @doc """
  Lay out the parsed graph bottom-up. Returns %{nodes: [%{id,type,label,x,y}],
  edges: [%{from,to}]}. Roots (no incoming edges) sit at the bottom (high y);
  effects climb upward (low y). Siblings spread horizontally.
  """
  def layout(%{nodes: nodes, edges: edges} = input) do
    clouds = Map.get(input, :clouds, [])
    cloud_members = MapSet.new(Enum.flat_map(clouds, & &1.members))
    ids = MapSet.new(Enum.map(nodes, & &1.id))
    # only keep edges whose endpoints exist
    edges =
      Enum.filter(edges, fn e -> MapSet.member?(ids, e.from) and MapSet.member?(ids, e.to) end)

    # Split into forward edges (for depth) and back-edges (loops, for rendering).
    {forward, back} = split_forward_back(edges)

    succ = Enum.group_by(forward, & &1.from, & &1.to)
    pred = Enum.group_by(forward, & &1.to, & &1.from)

    # depth = longest path from a root (source -> target adds depth)
    roots = Enum.filter(nodes, fn n -> not Map.has_key?(pred, n.id) end)
    depth = Enum.reduce(roots, %{}, fn n, d -> Map.put(d, n.id, 0) end)

    # iterative relaxation until stable (forward edges only, so it converges)
    depth =
      Enum.reduce(1..length(nodes), depth, fn _, d ->
        Enum.reduce(forward, d, fn e, acc ->
          cur = Map.get(acc, e.from, 0)
          Map.update(acc, e.to, cur + 1, fn v -> max(v, cur + 1) end)
        end)
      end)

    # Side-car lift: a non-cloud node that feeds a cloud leg (amplifier) OR is a
    # root feeding mid-tree targets should sit beside its target's row, not at
    # the canvas bottom. Lift its depth to (shallowest target depth - 1).
    depth =
      Enum.reduce(nodes, depth, fn n, d ->
        if MapSet.member?(cloud_members, n.id) do
          d
        else
          targets = Map.get(succ, n.id, [])
          target_depths = Enum.map(targets, &Map.get(d, &1, 0))

          if target_depths == [] do
            d
          else
            lift = max(Enum.min(target_depths) - 1, 0)
            Map.update(d, n.id, lift, fn v -> max(v, lift) end)
          end
        end
      end)

    depth =
      Enum.reduce(1..length(nodes), depth, fn _, d ->
        Enum.reduce(forward, d, fn e, acc ->
          cur = Map.get(acc, e.from, 0)
          Map.update(acc, e.to, cur + 1, fn v -> max(v, cur + 1) end)
        end)
      end)

    maxd = if map_size(depth) == 0, do: 0, else: Enum.max(Map.values(depth))

    # y: stack depths from top (maxd) to bottom (0), spacing by the max box
    # height at each depth so tall boxes never overlap their neighbors.
    by_depth = Enum.group_by(nodes, fn n -> Map.get(depth, n.id, 0) end)
    gap = 56

    y =
      Enum.reduce(maxd..0//-1, {20, %{}}, fn d, {cursor, acc} ->
        max_h =
          by_depth |> Map.get(d, []) |> Enum.map(&box_height(&1.label)) |> Enum.max(fn -> 0 end)

        {cursor + max_h + gap,
         Map.merge(acc, Map.new(by_depth[d] || [], fn n -> {n.id, cursor} end))}
      end)
      |> elem(1)

    # x: group by depth, spread horizontally with a uniform gap.
    x =
      Enum.reduce(by_depth, %{}, fn {_d, ns}, acc ->
        gap = 72
        total = length(ns) * @node_w + gap * (length(ns) - 1)
        start = -total / 2

        ns
        |> Enum.sort_by(& &1.id)
        |> Enum.with_index()
        |> Enum.reduce(acc, fn {n, i}, a -> Map.put(a, n.id, start + i * (@node_w + gap)) end)
      end)

    # Cloud skeleton: the cloud is the ANCHOR — A centered on top, B and C
    # below it, D and D' below those, all symmetric about a shared center line.
    # The generic depth-grid spread must not skew it, so cloud members are
    # re-placed explicitly here, with equal-width columns so the grid reads
    # clean. Non-cloud nodes keep their spread positions.
    x =
      Enum.reduce(clouds, x, fn cld, acc ->
        mem = Enum.filter(nodes, &(&1.id in cld.members))

        if mem == [] do
          acc
        else
          place_cloud(acc, mem)
        end
      end)

    # Side-car x override: an amplifier feeding a cloud leg sits BESIDE the
    # cloud source at the same row (e.g. 1.11 right of C, both feeding D').
    x =
      Enum.reduce(forward, x, fn e, acc ->
        if MapSet.member?(cloud_members, e.to) and not MapSet.member?(cloud_members, e.from) do
          cloud_src =
            pred[e.to]
            |> Enum.find(&MapSet.member?(cloud_members, &1))

          if cloud_src do
            cx = Map.get(acc, cloud_src, 0)
            Map.put(acc, e.from, cx + @node_w + 72)
          else
            acc
          end
        else
          acc
        end
      end)

    nodes =
      Enum.map(nodes, fn n ->
        n
        |> Map.put(:x, Map.get(x, n.id, 0))
        |> Map.put(:y, Map.get(y, n.id, 0))
      end)

    # Rule: a non-cloud node must NEVER sit inside a cloud group's rect.
    # Compute each cloud's rect, then push any intruding node below the cloud.
    nodes =
      Enum.reduce(clouds, nodes, fn cld, acc ->
        mem = Enum.filter(acc, &(&1.id in cld.members))

        if mem == [] do
          acc
        else
          cx = Enum.min(Enum.map(mem, & &1.x)) - 16
          cy = Enum.min(Enum.map(mem, & &1.y)) - 16
          cw = Enum.max(Enum.map(mem, & &1.x)) + 256 - cx

          ch =
            Enum.max(Enum.map(mem, & &1.y)) + Enum.max(Enum.map(mem, &box_height(&1.label))) - cy +
              16

          Enum.map(acc, fn n ->
            if n.id in cld.members do
              n
            else
              inside = n.x > cx and n.x < cx + cw and n.y > cy and n.y < cy + ch

              if inside do
                %{n | y: cy + ch + 40}
              else
                n
              end
            end
          end)
        end
      end)

    numbers = number_nodes(nodes, forward)
    stored = Map.get(input, :numbers, %{})
    letters = letter_labels(nodes, forward)

    nodes =
      Enum.map(nodes, fn n ->
        n
        |> Map.put(:number, Map.get(stored, n.id, Map.get(numbers, n.id, "")))
        |> Map.put(:letter, Map.get(letters, n.id, ""))
      end)

    rects = cloud_rects(nodes, clouds)
    edges = Enum.map(forward, &Map.put(&1, :path, route_edge(&1, nodes, rects, false)))
    back = Enum.map(back, &Map.put(&1, :path, route_edge(&1, nodes, rects, true)))

    %{nodes: nodes, edges: edges, back_edges: back, clouds: clouds}
  end

  # ---- Edge routing -------------------------------------------------------
  # Rule: a line has no permission to cross a cloud group's rect. Straight
  # line when clear; when it would cross, route around the cloud with an
  # orthogonal staircase (down the source column, across outside the cloud,
  # up into the target). Back-edges (loops) keep the curved arc.
  #
  # ponytail: staircase detour, not a full obstacle-avoiding router. Upgrade
  # path: if edges ever need to weave between multiple rects, swap this for a
  # proper A*/visibility-graph router.

  # Cloud rects + member sets: derived from each cloud's member boxes, padded
  # 16px — same math the view duplicates. Computed once, shared by routing.
  defp cloud_rects(nodes, clouds) do
    Enum.map(clouds, fn cld ->
      mem = Enum.filter(nodes, &(&1.id in cld.members))

      if mem == [] do
        nil
      else
        cx = Enum.min(Enum.map(mem, & &1.x)) - 16
        cy = Enum.min(Enum.map(mem, & &1.y)) - 16
        cw = Enum.max(Enum.map(mem, & &1.x)) + @node_w - cx + 16
        ch = Enum.max(Enum.map(mem, fn m -> m.y + box_height(m.label) end)) - cy + 16

        {{cx, cy, cx + cw, cy + ch}, MapSet.new(cld.members)}
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  # Anchor points: forward edge leaves the source's TOP center and enters the
  # target's BOTTOM center (the facing faces, per Dettmer's bottom-up CRT).
  # Back-edge (loop) leaves the source's BOTTOM center and enters the target's
  # TOP center — arced, never straight (a straight loop reads as bidirectional).
  #
  # Cloud-internal edges (both endpoints in the same cloud) are exempt from the
  # no-crossing rule: they live inside the cloud by design and route straight.
  defp route_edge(%{from: from, to: to} = e, nodes, cloud_rects, loop?) do
    src = Enum.find(nodes, &(&1.id == from))
    dst = Enum.find(nodes, &(&1.id == to))

    if is_nil(src) or is_nil(dst) do
      ""
    else
      x1 = src.x + div(box_width(src.label), 2)
      y1 = src.y
      x2 = dst.x + div(box_width(dst.label), 2)
      y2 = dst.y + box_height(dst.label)

      cond do
        loop? -> arc(x1, y1, x2, y2)
        same_cloud?(from, to, cloud_rects) -> "M #{x1} #{y1} L #{x2} #{y2}"
        true -> route_straight_or_around(e, x1, y1, x2, y2, cloud_rects)
      end
    end
  end

  defp same_cloud?(from, to, cloud_rects) do
    Enum.any?(cloud_rects, fn {_rect, members} ->
      from in members and to in members
    end)
  end

  # Cloud skeleton: A centered, B/C below, D/D' below those — symmetric about
  # the cloud's center line, equal column widths, wide gaps so the shape reads.
  # Column width = widest member box so nothing looks ragged.
  defp place_cloud(x, mem) do
    objectives = Enum.filter(mem, &(&1.type == "CommonObjective"))
    needs = Enum.sort_by(Enum.filter(mem, &(&1.type == "Need")), & &1.id)
    wants = Enum.sort_by(Enum.filter(mem, &(&1.type == "Want")), & &1.id)

    col_w = @node_w
    gap = 80
    # center line: the y-axis the whole cloud is symmetric about (from the
    # spread positions already in `x`, before we overwrite them)
    center =
      Enum.sum(Enum.map(mem, fn m -> Map.get(x, m.id, 0) + div(col_w, 2) end)) / length(mem)

    place = fn acc, ids -> place_row(acc, ids, center, col_w, gap) end

    x
    |> place.(objectives)
    |> place.(needs)
    |> place.(wants)
  end

  # A row of boxes centered on `center`: leftmost starts at center - row_w/2.
  defp place_row(x, ids, center, col_w, gap) do
    row_w = length(ids) * col_w + max(length(ids) - 1, 0) * gap
    start = center - row_w / 2

    Enum.reduce(Enum.with_index(ids), x, fn {n, i}, acc ->
      Map.put(acc, n.id, start + i * (col_w + gap))
    end)
  end

  defp arc(x1, y1, x2, y2) do
    mx = (x1 + x2) / 2
    my = min(y1, y2) - 60
    "M #{x1} #{y1} Q #{mx} #{my} #{x2} #{y2}"
  end

  # Straight line unless it crosses a cloud rect; then staircase around it.
  # An edge that touches a cloud member (source or target) is exempt: it
  # legitimately attaches to the cloud and leaves it. Only an edge with BOTH
  # endpoints outside the cloud must detour around it.
  defp route_straight_or_around(%{from: from, to: to}, x1, y1, x2, y2, rects) do
    blocker =
      Enum.find(rects, fn {r, members} ->
        from not in members and to not in members and segment_intersects_rect?(x1, y1, x2, y2, r)
      end)

    if blocker do
      route_around(x1, y1, x2, y2, elem(blocker, 0))
    else
      "M #{x1} #{y1} L #{x2} #{y2}"
    end
  end

  # Orthogonal detour: leave source, run to a lane just outside the blocker's
  # x-band (pick the nearer side), travel vertically past it, re-enter.
  # ponytail: picks the nearer side; if both sides are blocked it still routes
  # to one of them — a real solver would backtrack.
  defp route_around(x1, y1, x2, y2, {bx1, by1, bx2, by2}) do
    left_gap = x1 - bx1
    right_gap = bx2 - x1
    lane = if abs(left_gap) <= abs(right_gap), do: bx1 - @pad, else: bx2 + @pad

    # staircase: down from source, across to the lane, vertically to target's
    # row, across back to the target column, down into it.
    mid_y = if y2 > by1 and y2 < by2, do: by2 + @pad, else: div(y1 + y2, 2)

    "M #{x1} #{y1} L #{x1} #{mid_y - 40} L #{lane} #{mid_y - 40} L #{lane} #{mid_y} L #{x2} #{mid_y} L #{x2} #{y2}"
  end

  # Segment vs axis-aligned rect: true if any part of the segment passes
  # through the rect interior (endpoints on the edge don't count — the edge
  # is allowed to touch, just not cross).
  defp segment_intersects_rect?(x1, y1, x2, y2, {rx1, ry1, rx2, ry2}) do
    dx = x2 - x1
    dy = y2 - y1
    t0 = 0.0
    t1 = 1.0

    clip = fn p, q, {t0, t1} ->
      if p == 0.0 do
        if q < 0.0, do: {:done, nil}, else: {:ok, {t0, t1}}
      else
        t = q / p

        if p < 0.0 do
          if t > t1, do: {:done, nil}, else: {:ok, {max(t0, t), t1}}
        else
          if t < t0, do: {:done, nil}, else: {:ok, {t0, min(t1, t)}}
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

  @doc """
  Split edges into forward edges (for layout/numbering) and back-edges (loops,
  for rendering). Uses DFS: an edge from->to is a back-edge if `to` is an
  ancestor of `from` in the DFS tree (i.e., it closes a cycle).
  """
  def split_forward_back(edges) do
    succ = Enum.group_by(edges, & &1.from, & &1.to)
    nodes = edges |> Enum.flat_map(&[&1.from, &1.to]) |> Enum.uniq()

    # 3-color DFS: white = unvisited, gray = on the current recursion stack
    # (an ancestor), black = fully processed. A back-edge points to a GRAY
    # node — that's what closes a cycle. An edge to a black node is a
    # forward/cross edge, not a loop.
    {back, _, _} =
      Enum.reduce(nodes, {MapSet.new(), MapSet.new(), MapSet.new()}, fn start,
                                                                        {back, gray, black} ->
        if MapSet.member?(gray, start) or MapSet.member?(black, start) do
          {back, gray, black}
        else
          dfs(start, succ, back, gray, black)
        end
      end)

    Enum.split_with(edges, fn e -> not MapSet.member?(back, {e.from, e.to}) end)
  end

  defp dfs(node, succ, back, gray, black) do
    gray = MapSet.put(gray, node)

    {back, gray, black} =
      Enum.reduce(Map.get(succ, node, []), {back, gray, black}, fn n, {b, g, blk} ->
        cond do
          MapSet.member?(g, n) ->
            # n is on the current path -> this edge closes a cycle
            {MapSet.put(b, {node, n}), g, blk}

          MapSet.member?(blk, n) ->
            # n fully processed -> forward/cross edge, not a loop
            {b, g, blk}

          true ->
            dfs(n, succ, b, g, blk)
        end
      end)

    gray = MapSet.delete(gray, node)
    black = MapSet.put(black, node)
    {back, gray, black}
  end

  @doc """
  Cloud internals keep their A/B/C/D/D' letters; the CRT chain (UDE/IE) uses
  the flat numbers. Returns id -> letter for cloud internals only.
  """
  def letter_labels(nodes, edges) do
    pred = Enum.group_by(edges, & &1.to, & &1.from)

    # two Needs feeding the same objective -> B and C (by x, left=B)
    need_letters =
      nodes
      |> Enum.filter(&(&1.type == "Need"))
      |> Enum.group_by(fn w -> List.first(Map.get(pred, w.id, [])) || :none end)
      |> Enum.flat_map(fn {_parent, needs} ->
        needs
        |> Enum.sort_by(& &1.x)
        |> Enum.with_index()
        |> Enum.map(fn {n, i} -> {n.id, if(i == 0, do: "B", else: "C")} end)
      end)
      |> Map.new()

    # two Wants -> D and D' by x-position (left=D, right=D')
    want_letters =
      nodes
      |> Enum.filter(&(&1.type == "Want"))
      |> Enum.sort_by(& &1.x)
      |> Enum.with_index()
      |> Enum.map(fn {w, i} -> {w.id, if(i == 0, do: "D", else: "D'")} end)
      |> Map.new()

    Enum.reduce(nodes, %{}, fn n, acc ->
      letter =
        case n.type do
          "CommonObjective" -> "A"
          "Need" -> Map.get(need_letters, n.id, "B")
          "Want" -> Map.get(want_letters, n.id, "D")
          "Conflict" -> ""
          _ -> ""
        end

      if letter == "", do: acc, else: Map.put(acc, n.id, letter)
    end)
  end

  @doc """
  Assign flat per-branch numbers to the CRT chain only (UDE + IntermediateEffect).
  Each UDE is a branch (1, 2, 3...). The UDE itself is N.0; every IE that
  transitively feeds it gets N.1, N.2, N.3... in a flat BFS sequence regardless
  of depth — so we never get 1.1.1.1.1.18. Cloud internals (CommonObjective,
  Need, Want, Conflict) are NOT numbered — they keep their A/B/C/D/D' letters.
  """
  def number_nodes(nodes, edges) do
    pred = Enum.group_by(edges, & &1.to, & &1.from)
    # only UDE + IntermediateEffect are numbered; cloud internals keep letters
    chain =
      nodes
      |> Enum.filter(&(&1.type in ["UndesirableEffect", "IntermediateEffect"]))
      |> MapSet.new(& &1.id)

    udes =
      nodes
      |> Enum.filter(&(&1.type == "UndesirableEffect"))
      |> Enum.sort_by(& &1.id)
      |> Enum.with_index(1)

    Enum.reduce(udes, %{}, fn {ude, branch}, acc ->
      acc = Map.put(acc, ude.id, "#{branch}.0")

      # BFS over predecessors, flat numbering per branch (counter resets each branch)
      {acc, _, _} =
        Enum.reduce_while(1..length(nodes), {acc, [ude.id], 1}, fn _, {a, frontier, counter} ->
          {a, next, counter} =
            Enum.reduce(frontier, {a, [], counter}, fn id, {acc2, next, c} ->
              Enum.reduce(Map.get(pred, id, []), {acc2, next, c}, fn p, {acc3, next3, c3} ->
                if Map.has_key?(acc3, p) or not MapSet.member?(chain, p) do
                  {acc3, next3, c3}
                else
                  {Map.put(acc3, p, "#{branch}.#{c3}"), [p | next3], c3 + 1}
                end
              end)
            end)

          if next == [], do: {:halt, {a, next, counter}}, else: {:cont, {a, next, counter}}
        end)

      acc
    end)
  end

  # Box height grows with label length. Text area is ~176px (with badge) at
  # 14px sans-serif — ~24 chars/line. 18px per line, min 44px.
  # Word-wrapping can cost an extra ragged line, so +1 of slack.
  def box_height(label) do
    lines = max(1, div(String.length(label), @wrap_cols) + 2)
    max(44, lines * 18 + 14)
  end

  # Word-wrap at ~24 chars so no line splits mid-word.
  def wrap_label(label) do
    label
    |> String.split(" ")
    |> Enum.reduce([""], fn word, [line | rest] ->
      if String.length(line) == 0 do
        [word | rest]
      else
        candidate = line <> " " <> word

        if String.length(candidate) <= @wrap_cols,
          do: [candidate | rest],
          else: [word, line | rest]
      end
    end)
    |> Enum.reverse()
  end

  # Fixed box width — the manual default. Height is the only thing that grows
  # (a floor). Right text margin stays constant because the text column is
  # constant; ragged line endings are just the text, not the box.
  def box_width(_label), do: @node_w
end
