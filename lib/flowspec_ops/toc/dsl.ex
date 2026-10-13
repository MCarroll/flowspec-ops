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

  @node_types ~w(UndesirableEffect IntermediateEffect AndJunctior Given Changeable
                 CommonObjective Need Want Conflict Injection)

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

  @doc "Parse DSL text into %{nodes: [%{id, type, label}], edges: [%{from, to}]}."
  def parse(dsl) when is_binary(dsl) do
    dsl
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.reduce(%{nodes: [], edges: []}, &parse_line/2)
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
  def layout(%{nodes: nodes, edges: edges}) do
    ids = MapSet.new(Enum.map(nodes, & &1.id))
    # only keep edges whose endpoints exist
    edges = Enum.filter(edges, fn e -> MapSet.member?(ids, e.from) and MapSet.member?(ids, e.to) end)

    succ = Enum.group_by(edges, & &1.from, & &1.to)
    pred = Enum.group_by(edges, & &1.to, & &1.from)

    # depth = longest path from a root (source -> target adds depth)
    roots = Enum.filter(nodes, fn n -> not Map.has_key?(pred, n.id) end)
    depth = Enum.reduce(roots, %{}, fn n, d -> Map.put(d, n.id, 0) end)

    # iterative relaxation until stable
    depth =
      Enum.reduce(1..length(nodes), depth, fn _, d ->
        Enum.reduce(edges, d, fn e, acc ->
          cur = Map.get(acc, e.from, 0)
          Map.update(acc, e.to, cur + 1, fn v -> max(v, cur + 1 + 1) end)
        end)
      end)

    maxd = if map_size(depth) == 0, do: 0, else: Enum.max(Map.values(depth))

    # y: depth 0 at bottom (maxd*cell), depth maxd at top (0)
    cell_y = 110
    y = Map.new(depth, fn {id, d} -> {id, (maxd - d) * cell_y + 20} end)

    # x: group by depth, spread horizontally
    by_depth = Enum.group_by(nodes, fn n -> Map.get(depth, n.id, 0) end)
    x =
      Enum.reduce(by_depth, %{}, fn {d, ns}, acc ->
        w = 240
        gap = 40
        total = length(ns)
        start = -(total - 1) * (w + gap) / 2
        ns
        |> Enum.sort_by(& &1.id)
        |> Enum.with_index()
        |> Enum.reduce(acc, fn {n, i}, a -> Map.put(a, n.id, start + i * (w + gap) + 400) end)
      end)

    nodes =
      Enum.map(nodes, fn n ->
        n
        |> Map.put(:x, Map.get(x, n.id, 0))
        |> Map.put(:y, Map.get(y, n.id, 0))
      end)

    %{nodes: nodes, edges: edges}
  end
end
