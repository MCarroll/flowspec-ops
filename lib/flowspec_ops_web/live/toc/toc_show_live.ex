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
       show_dsl: true
     )}
  end

  @impl true
  def handle_event("toggle_dsl", _params, socket) do
    {:noreply, assign(socket, show_dsl: not socket.assigns.show_dsl)}
  end

  @impl true
  def handle_event("dsl_changed", %{"dsl" => dsl}, socket) do
    diagram = socket.assigns.diagram

    case TOC.update_diagram(diagram, %{dsl: dsl}) do
      {:ok, updated} ->
        graph = DSL.layout(DSL.parse(dsl))

        Phoenix.PubSub.broadcast(
          FlowspecOps.PubSub,
          @topic <> ":" <> diagram.id,
          {:graph_updated, dsl}
        )

        {:noreply, assign(socket, diagram: updated, dsl: dsl, graph: graph)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:graph_updated, dsl}, socket) do
    graph = DSL.layout(DSL.parse(dsl))
    {:noreply, assign(socket, dsl: dsl, graph: graph)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-3">
          <.link
            navigate={~p"/toc"}
            class="text-sm text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300"
          >
            ← Back
          </.link>
          <h1 class="text-xl font-semibold text-zinc-900 dark:text-zinc-100">{@diagram.name}</h1>
        </div>
        <div class="flex items-center gap-3 text-xs text-zinc-400">
          <span>{length(@graph.nodes)} nodes · {length(@graph.edges)} edges</span>
          <button
            type="button"
            phx-click="toggle_dsl"
            class="rounded-md border border-zinc-300 px-2 py-1 font-medium text-zinc-600 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
          >
            {if @show_dsl, do: "Hide DSL", else: "Show DSL"}
          </button>
        </div>
      </div>

      <div class="grid grid-cols-3 gap-4">
        <!-- Left: DSL editor (1/3 width, hideable) -->
        <%= if @show_dsl do %>
          <div class="rounded-lg border border-zinc-200 dark:border-zinc-800">
            <div class="border-b border-zinc-200 px-3 py-2 text-xs font-medium text-zinc-500 dark:border-zinc-800 dark:text-zinc-400">
              DSL — the diagram as text
            </div>
            <textarea
              id="dsl-editor"
              phx-debounce="300"
              phx-change="dsl_changed"
              name="dsl"
              class="h-[70vh] w-full resize-none bg-zinc-50 p-3 font-mono text-xs text-zinc-800 outline-none dark:bg-zinc-900 dark:text-zinc-100"
            ><%= @dsl %></textarea>
          </div>
        <% end %>

        <!-- Right: SVG render (2/3 width, or full when DSL hidden) -->
        <div
          id="toc-render"
          phx-hook="TocZoom"
          class={[
            "overflow-auto rounded-lg border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-900",
            if(@show_dsl, do: "col-span-2", else: "col-span-3")
          ]}
        >
          <div class="border-b border-zinc-200 px-3 py-2 text-xs font-medium text-zinc-500 dark:border-zinc-800 dark:text-zinc-400">
            Render · Ctrl+scroll to zoom
          </div>
          <div class="p-4">
            <.svg_graph graph={@graph} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp svg_graph(assigns) do
    ~H"""
    <svg
      viewBox={view_box(@graph.nodes)}
      data-base-w={view_box_width(@graph.nodes)}
      data-base-h={view_box_height(@graph.nodes)}
      style="width: {view_box_width(@graph.nodes)}px; height: {view_box_height(@graph.nodes)}px; max-width: none;"
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
        <% label = if n.letter != "", do: n.letter, else: n.number %>
        <% bw = if badge != "", do: max(44, String.length(label) * 7 + 10), else: 0 %>
        <% tx = n.x + 6 + bw + 8 %>
        <g>
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
          <%= if badge != "" do %>
            <% label =
              if n.letter != "", do: n.letter, else: if(n.number == "", do: "—", else: n.number) %>
            <% bw = max(44, String.length(label) * 7 + 10) %>
            <rect x={n.x + 6} y={n.y + 6} width={bw} height="18" rx="3" fill={stroke} />
            <text
              x={n.x + 6 + div(bw, 2)}
              y={n.y + 19}
              text-anchor="middle"
              font-size="10"
              font-family="monospace"
              font-weight="600"
              fill="#fff"
            >
              {label}
            </text>
          <% end %>
          <text x={tx} y={n.y + 20} font-size="14" font-family="sans-serif" fill="#1e1e1e">
            <%= for {line, i} <- Enum.with_index(wrap_label(n.label)) do %>
              <tspan x={tx} dy={if(i == 0, do: 0, else: 18)}>{line}</tspan>
            <% end %>
          </text>
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
  defp view_box(nodes) do
    {min_x, min_y, w, h} = bounds(nodes)
    "#{min_x} #{min_y} #{w} #{h}"
  end

  defp view_box_width(nodes) do
    {_, _, w, _} = bounds(nodes)
    w
  end

  defp view_box_height(nodes) do
    {_, _, _, h} = bounds(nodes)
    h
  end

  defp bounds(nodes) do
    xs = Enum.map(nodes, & &1.x)
    ys = Enum.map(nodes, & &1.y)
    min_x = Enum.min(xs) - 20
    min_y = Enum.min(ys) - 20
    max_x = Enum.max(xs) + @node_w + 20
    max_y = Enum.max(Enum.map(nodes, fn n -> n.y + box_height(n.label) end)) + 60
    {min_x, min_y, max_x - min_x, max_y - min_y}
  end

  # Box metrics — single source of truth in DSL.
  defp box_height(label), do: DSL.box_height(label)
  defp wrap_label(label), do: DSL.wrap_label(label)

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
end
