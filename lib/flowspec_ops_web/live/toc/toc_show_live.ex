defmodule FlowspecOpsWeb.TOC.TocShowLive do
  use FlowspecOpsWeb, :live_view

  alias FlowspecOps.TOC
  alias FlowspecOps.TOC.DSL

  @node_w 240

  @topic "toc_diagram"

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    diagram = TOC.get_diagram!(id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(FlowspecOps.PubSub, @topic <> ":" <> id)
    end

    graph = DSL.layout(DSL.parse(diagram.dsl || ""))

    {:ok,
     socket
     |> assign(
       page_title: diagram.name,
       diagram: diagram,
       dsl: diagram.dsl || "",
       graph: graph,
       tension: graph.tension,
       versions: TOC.list_versions(diagram.id),
       editing: nil
     )}
  end

  @impl true
  def handle_event("edit_node", %{"id" => id}, socket) do
    node = Enum.find(socket.assigns.graph.nodes, &(&1.id == id))

    if node do
      {:noreply, assign(socket, editing: %{id: id, label: node.label, letter: node.letter || ""})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing: nil)}
  end

  @impl true
  def handle_event("commit_edit", %{"label" => label}, socket) do
    %{id: id} = socket.assigns.editing
    dsl = set_node_label(socket.assigns.dsl, id, label)

    case TOC.update_diagram(socket.assigns.diagram, %{dsl: dsl}) do
      {:ok, updated} ->
        graph = DSL.layout(DSL.parse(dsl))

        Phoenix.PubSub.broadcast(
          FlowspecOps.PubSub,
          @topic <> ":" <> diagram_id(socket),
          {:graph_updated, dsl}
        )

        {:noreply, assign(socket, diagram: updated, dsl: dsl, graph: graph, editing: nil)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  # Rewrite one node's label in the DSL, keeping its type. Insert-only nodes
  # (placeholders have no DSL line — they're synthesized at layout).
  # ponytail: regex line replace, assumes one node statement per line.
  defp set_node_label(dsl, id, label) do
    label = String.trim(label || "")

    if label == "" do
      dsl
    else
      escaped = String.replace(label, "\"", "\\\"")

      case Regex.run(~r/^(node\s+#{id}\s*:\s*\w+\s*)"[^"]*"/m, dsl) do
        [full, head] -> String.replace(dsl, full, head <> "\"#{escaped}\"", global: false)
        nil -> dsl
      end
    end
  end

  @impl true
  def handle_event("save_version", %{"note" => note}, socket) do
    case TOC.create_version(socket.assigns.diagram, blank_to_nil(note)) do
      {:ok, version} ->
        {:noreply,
         socket
         |> put_flash(:info, "Saved version #{version.version}")
         |> assign(versions: TOC.list_versions(socket.assigns.diagram.id))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not save version")}
    end
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(text) when is_binary(text) do
    case String.trim(text) do
      "" -> nil
      t -> t
    end
  end

  @impl true
  def handle_event("edit_tension", %{"tension" => tension}, socket) do
    # rewrite the tension line in the DSL (insert if absent), keep the rest
    dsl = upsert_tension(socket.assigns.dsl, tension)

    case TOC.update_diagram(socket.assigns.diagram, %{dsl: dsl}) do
      {:ok, updated} ->
        graph = DSL.layout(DSL.parse(dsl))

        Phoenix.PubSub.broadcast(
          FlowspecOps.PubSub,
          @topic <> ":" <> diagram_id(socket),
          {:graph_updated, dsl}
        )

        {:noreply, assign(socket, diagram: updated, dsl: dsl, graph: graph, tension: graph.tension)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("rename", %{"name" => name}, socket) do
    case TOC.update_diagram(socket.assigns.diagram, %{name: name}) do
      {:ok, updated} ->
        {:noreply, assign(socket, diagram: updated, page_title: name)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  defp diagram_id(socket), do: socket.assigns.diagram.id

  # Insert or replace the `tension "..."` line; nil/empty clears it.
  defp upsert_tension(dsl, text) do
    text = String.trim(text || "")

    lines =
      dsl
      |> String.split("\n")
      |> Enum.reject(&String.match?(&1, ~r/^\s*tension\s+"[^"]*"\s*;?\s*$/))

    if text == "" do
      Enum.join(lines, "\n")
    else
      Enum.join(lines ++ [~s(tension "#{text}")], "\n")
    end
  end

  @impl true
  def handle_info({:graph_updated, dsl}, socket) do
    graph = DSL.layout(DSL.parse(dsl))
    {:noreply, assign(socket, dsl: dsl, graph: graph, tension: graph.tension)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div class="flex items-center gap-3">
          <.link
            navigate={~p"/toc"}
            class="text-sm text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300"
          >
            ← Back
          </.link>
          <input
            type="text"
            value={@diagram.name}
            phx-change="rename"
            phx-debounce="500"
            name="name"
            style="color: #18181b;"
            class="rounded-md border border-zinc-300 bg-white px-2 py-1 text-xl font-semibold focus:border-zinc-400 focus:outline-none"
          />
        </div>
        <!-- Clouds: versions + save, grouped right on the title line.
             Save a version to pin in a CRT; swap the pin when a newer one is dry. -->
        <%= if @diagram.kind == "cloud" do %>
          <div class="flex items-center gap-2 text-xs">
            <%= if @versions == [] do %>
              <span class="text-zinc-400">no versions yet</span>
            <% else %>
              <%= for v <- @versions do %>
                <span class="rounded bg-zinc-100 px-2 py-0.5 font-mono text-zinc-600 dark:bg-zinc-800 dark:text-zinc-300">
                  v{v.version}<%= if v.note, do: " · #{v.note}" %>
                </span>
              <% end %>
            <% end %>
            <form phx-submit="save_version" class="flex gap-1">
              <input
                type="text"
                name="note"
                placeholder="note"
                class="w-24 rounded border border-zinc-300 px-2 py-1 text-xs dark:border-zinc-700 dark:bg-zinc-800"
              />
              <button
                type="submit"
                class="rounded-md bg-zinc-900 px-2 py-1 font-medium text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900"
              >
                Save version
              </button>
            </form>
          </div>
        <% else %>
          <span class="text-xs text-zinc-400">
            {length(@graph.nodes)} nodes · {length(@graph.edges)} edges
          </span>
        <% end %>
      </div>

      <!-- Tension statement: the tug-of-war, written first, above the cloud.
           Editable inline; agent edits it through the same DSL line. -->
      <div class="rounded-lg border border-amber-200 bg-amber-50 p-3 dark:border-amber-900 dark:bg-amber-950/30">
        <label class="mb-1 block text-xs font-semibold uppercase tracking-wide text-amber-700 dark:text-amber-400">
          Tension — the tug of war
        </label>
        <textarea
          phx-change="edit_tension"
          phx-debounce="500"
          name="tension"
          rows="2"
          placeholder="Feel the pull first… e.g. I need to build AI data centers, and public resentment is growing"
          class="w-full resize-none bg-transparent text-sm text-zinc-800 outline-none placeholder:text-amber-700/40 dark:text-zinc-100"
        ><%= @tension %></textarea>
      </div>

      <!-- SVG render: the cloud is the whole surface. No DSL editor —
           the DSL is storage, edited through entity popups and the agent. -->
      <div
        id="toc-render"
        phx-hook="TocZoom"
        class="overflow-auto rounded-lg border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-900"
      >
        <div class="border-b border-zinc-200 px-3 py-2 text-xs font-medium text-zinc-500 dark:border-zinc-800 dark:text-zinc-400">
          Render · Ctrl+scroll to zoom · click a card to edit
        </div>
        <div class="p-4">
          <.svg_graph graph={@graph} />
        </div>
      </div>

      <!-- Centered edit popup (Flying Logic pattern): type, Enter commits,
           Escape cancels. Detached from the card — never an anchored popover. -->
      <%= if @editing do %>
        <div
          class="fixed inset-0 z-50 flex items-center justify-center bg-black/30"
          phx-click="cancel_edit"
          phx-window-keydown="cancel_edit"
          phx-key="Escape"
        >
          <form
            phx-submit="commit_edit"
            class="w-96 rounded-lg bg-white p-4 shadow-xl dark:bg-zinc-900"
            onclick="event.stopPropagation()"
          >
            <label class="mb-1 block text-xs font-semibold uppercase tracking-wide text-zinc-500">
              Edit <%= if @editing.letter != "", do: @editing.letter, else: "entity" %>
            </label>
            <textarea
              id="node-edit-input"
              name="label"
              rows="3"
              autofocus
              phx-hook="AutoSelect"
              class="w-full resize-none rounded-md border border-zinc-300 p-2 text-sm outline-none focus:border-zinc-500 dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-100"
            ><%= @editing.label %></textarea>
            <div class="mt-2 flex justify-end gap-2 text-xs">
              <span class="self-center text-zinc-400">Enter saves · Esc cancels</span>
              <button
                type="button"
                phx-click="cancel_edit"
                class="rounded-md border border-zinc-300 px-3 py-1 font-medium text-zinc-600 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="rounded-md bg-zinc-900 px-3 py-1 font-medium text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900"
              >
                Save
              </button>
            </div>
          </form>
        </div>
      <% end %>
    </div>
    """
  end

  defp svg_graph(assigns) do
    ~H"""
    <svg
      viewBox={view_box(@graph)}
      data-base-w={view_box_width(@graph)}
      data-base-h={view_box_height(@graph)}
      style="width: {view_box_width(@graph)}px; height: {view_box_height(@graph)}px; max-width: none;"
      xmlns="http://www.w3.org/2000/svg"
    >
      <!-- cloud groups: dashed container behind cloud members -->
      <%= for cld <- @graph.clouds || [] do %>
        <% members = Enum.filter(@graph.nodes, &(&1.id in cld.members)) %>
        <%= if members != [] do %>
          <% cx = Enum.min(Enum.map(members, & &1.x)) - 16 %>
          <% cy = Enum.min(Enum.map(members, & &1.y)) - 16 %>
          <% cw = Enum.max(Enum.map(members, & &1.x)) + 240 - cx + 16 %>
          <% ch =
            Enum.max(Enum.map(members, fn m -> m.y + box_height(m.label) end)) - cy + 16 %>
          <rect
            x={cx}
            y={cy}
            width={cw}
            height={ch}
            rx="14"
            fill="rgba(241,245,249,0.45)"
            stroke="#94a3b8"
            stroke-width="1.5"
            stroke-dasharray="6 4"
          />
          <text
            x={cx + 10}
            y={cy + 16}
            font-size="11"
            font-weight="700"
            fill="#64748b"
            font-family="monospace"
          >
            {cld.id}
          </text>
        <% end %>
      <% end %>

      <!-- edges: one <path> per edge, geometry computed in DSL.layout.
           A line never crosses a cloud rect — the router detours around it. -->
      <%= for e <- @graph.edges do %>
        <path d={e.path} fill="none" stroke="#fff" stroke-width="5" />
        <path d={e.path} fill="none" stroke="#94a3b8" stroke-width="2" marker-end="url(#arrow)" />
      <% end %>

      <!-- back-edges (reinforcing loops) — dashed red, curved -->
      <%= for e <- @graph.back_edges do %>
        <path
          d={e.path}
          fill="none"
          stroke="#e03131"
          stroke-width="2"
          stroke-dasharray="6 4"
          marker-end="url(#arrow-red)"
        />
      <% end %>

      <!-- assumptions: small dashed boxes beside each arrow -->
      <%= for a <- @graph.assumptions || [] do %>
        <% pos = assumption_box(@graph, a) %>
        <%= if pos do %>
          <g>
            <rect
              x={pos.x}
              y={pos.y}
              width={pos.w}
              height={pos.h}
              rx="4"
              fill="#fffdf5"
              stroke="#d0bfff"
              stroke-width="1.5"
              stroke-dasharray="4 3"
            />
            <text x={pos.x + 6} y={pos.y + 18} font-size="11" font-family="sans-serif" fill="#495057">
              <%= for {line, i} <- Enum.with_index(wrap_label(a.text)) do %>
                <tspan x={pos.x + 6} dy={if(i == 0, do: 0, else: 13)}>{line}</tspan>
              <% end %>
            </text>
          </g>
        <% end %>
      <% end %>

      <!-- AND connectors: circle where 2+ arrows converge into one target -->
      <%= for jc <- and_connectors(@graph) do %>
        <circle cx={jc.x} cy={jc.y} r="11" fill="#fff" stroke="#0b7285" stroke-width="2" />
        <text
          x={jc.x}
          y={jc.y + 4}
          text-anchor="middle"
          font-size="9"
          font-weight="700"
          fill="#0b7285"
          font-family="monospace"
        >
          AND
        </text>
      <% end %>

      <!-- nodes -->
      <%= for n <- @graph.nodes do %>
        <% {badge, fill, stroke} = Map.get(DSL.colors(), n.type, {"", "#f1f3f5", "#495057"}) %>
        <% h = box_height(n.label) %>
        <% label = badge_label(n) %>
        <% bw = if label != "", do: max(44, String.length(label) * 7 + 10), else: 0 %>
        <% tx = n.x + 6 + bw + 8 %>
        <g phx-click="edit_node" phx-value-id={n.id} style="cursor: pointer;">
          <!-- card: always solid. Placeholders read as empty via the dashed
               prompt text, not the border. -->
          <rect
            x={n.x}
            y={n.y}
            width="240"
            height={h}
            rx="6"
            fill={fill}
            stroke={stroke}
            stroke-width="2"
          />
          <!-- letter badge, same shape as on a tree -->
          <%= if label != "" do %>
            <% bh = 28 %>
            <rect x={n.x + 6} y={n.y + 6} width={bw} height={bh} rx="3" fill={stroke} />
            <text
              x={n.x + 6 + div(bw, 2)}
              y={n.y + 18}
              text-anchor="middle"
              font-size="10"
              font-family="monospace"
              font-weight="600"
              fill="#fff"
            >
              {label}
            </text>
            <text
              x={n.x + 6 + div(bw, 2)}
              y={n.y + 29}
              text-anchor="middle"
              font-size="8"
              font-family="monospace"
              font-weight="500"
              fill="#ffffffcc"
            >
              {node_display_id(n)}
            </text>
          <% end %>
          <%= if Map.get(n, :placeholder, false) do %>
            <!-- empty canonical slot: fill prompt under the badge -->
            <text
              x={tx}
              y={n.y + 20}
              font-size="11"
              font-family="sans-serif"
              font-style="italic"
              fill="#adb5bd"
            >
              click to fill — dialog or type
            </text>
          <% else %>
            <text x={tx} y={n.y + 20} font-size="14" font-family="sans-serif" fill="#1e1e1e">
              <%= for {line, i} <- Enum.with_index(wrap_label(n.label)) do %>
                <tspan x={tx} dy={if(i == 0, do: 0, else: 18)}>{line}</tspan>
              <% end %>
            </text>
          <% end %>
        </g>
      <% end %>

      <defs>
        <marker
          id="arrow"
          viewBox="0 0 10 10"
          refX="8"
          refY="5"
          markerWidth="10"
          markerHeight="10"
          orient="auto-start-reverse"
        >
          <path d="M 0 0 L 10 5 L 0 10 z" fill="#94a3b8" />
        </marker>
        <marker
          id="arrow-red"
          viewBox="0 0 10 10"
          refX="8"
          refY="5"
          markerWidth="10"
          markerHeight="10"
          orient="auto-start-reverse"
        >
          <path d="M 0 0 L 10 5 L 0 10 z" fill="#e03131" />
        </marker>
      </defs>
    </svg>
    """
  end

  # Tight viewBox from the actual node bounds, with padding, so the graph fills
  # the container instead of being scaled down by a fixed oversized viewBox.
  # Assumption boxes sit past the right edge of in-cloud nodes, so they extend
  # the bounds.
  defp view_box(graph) do
    {min_x, min_y, w, h} = bounds(graph.nodes)

    {min_x, min_y, w, h} =
      Enum.reduce(graph.assumptions || [], {min_x, min_y, w, h}, fn a, {nx, ny, w, h} ->
        case assumption_box(graph, a) do
          nil ->
            {nx, ny, w, h}

          %{x: x, y: y, w: bw, h: bh} ->
            {min(nx, x - 10), min(ny, y - 10), max(w, x + bw + 30 - nx), max(h, y + bh + 30 - ny)}
        end
      end)

    "#{min_x} #{min_y} #{w} #{h}"
  end

  defp view_box_width(graph), do: elem(bounds(graph.nodes), 2) + 260
  defp view_box_height(graph), do: elem(bounds(graph.nodes), 3)

  defp bounds(nodes) do
    xs = Enum.map(nodes, & &1.x)
    ys = Enum.map(nodes, & &1.y)
    min_x = Enum.min(xs) - 20
    min_y = Enum.min(ys) - 20
    max_x = Enum.max(xs) + @node_w + 20
    max_y = Enum.max(Enum.map(nodes, fn n -> n.y + box_height(n.label) end)) + 60
    {min_x, min_y, max_x - min_x, max_y - min_y}
  end

  defp box_height(label), do: DSL.box_height(label)
  defp wrap_label(label), do: DSL.wrap_label(label)

  # Badge sub-label: real nodes show their id; placeholders show nothing
  # (the letter badge already says it).
  defp node_display_id(%{placeholder: true}), do: ""
  defp node_display_id(%{id: id}), do: id

  # Badge text: cloud internals keep their A/B/C/D/D' letter; CRT chain nodes
  # (UDE + IE) get the type prefix so you can tell a UDE from an IE at a
  # glance — "UDE 1.0" vs "IE 1.11".
  defp badge_label(n) do
    cond do
      n.letter != "" ->
        n.letter

      n.number == "" ->
        "—"

      true ->
        {prefix, _, _} = Map.get(DSL.colors(), n.type, {"", "", ""})
        "#{prefix} #{n.number}"
    end
  end

  # Fan-in junction points: targets with 2+ incoming edges get an AND circle
  # just BELOW their bottom edge, where the converging arrows meet.
  defp and_connectors(graph) do
    graph.edges
    |> Enum.group_by(& &1.to)
    |> Enum.filter(fn {_to, es} -> length(es) >= 2 end)
    |> Enum.map(fn {to, _es} ->
      n = Enum.find(graph.nodes, &(&1.id == to))

      if n, do: %{x: n.x + div(@node_w, 2), y: n.y + box_height(n.label) + 8, id: to}, else: nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  # Assumption box: {x, y, w, h} beside its arrow's midpoint — to the right
  # for in-cloud arrows (the CRD cloud is on its side), above for CRT arrows.
  # ponytail: no collision check; sibling boxes can overlap — stack per-edge
  # when the visual noise actually bothers you.
  defp assumption_box(graph, %{from: from, to: to, text: text}) do
    src = Enum.find(graph.nodes, & &1.id == from)
    dst = Enum.find(graph.nodes, & &1.id == to)

    cond do
      is_nil(src) or is_nil(dst) ->
        nil

      in_same_cloud?(graph, from, to) ->
        %{x: src.x + @node_w + 10, y: div(src.y + dst.y, 2) + 10, w: 200, h: box_height(text)}

      true ->
        %{x: div(src.x + dst.x, 2) - 100, y: div(src.y + dst.y, 2), w: 200, h: box_height(text)}
    end
  end

  defp in_same_cloud?(graph, from, to) do
    Enum.any?(graph.clouds || [], fn c -> from in c.members and to in c.members end)
  end
end
