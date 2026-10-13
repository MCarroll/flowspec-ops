defmodule FlowspecOpsWeb.TOC.TocShowLive do
  use FlowspecOpsWeb, :live_view

  alias FlowspecOps.TOC
  alias FlowspecOps.TOC.DSL

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
          <.link navigate={~p"/toc"} class="text-sm text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300">
            ← Back
          </.link>
          <h1 class="text-xl font-semibold text-zinc-900 dark:text-zinc-100"><%= @diagram.name %></h1>
        </div>
        <div class="flex items-center gap-3 text-xs text-zinc-400">
          <span><%= length(@graph.nodes) %> nodes · <%= length(@graph.edges) %> edges</span>
          <button
            type="button"
            phx-click="toggle_dsl"
            class="rounded-md border border-zinc-300 px-2 py-1 font-medium text-zinc-600 hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
          >
            <%= if @show_dsl, do: "Hide DSL", else: "Show DSL" %>
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
          class={["overflow-auto rounded-lg border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-900", if(@show_dsl, do: "col-span-2", else: "col-span-3")]}
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
      <!-- edges -->
      <%= for e <- @graph.edges do %>
        <% from = Enum.find(@graph.nodes, &(&1.id == e.from)) %>
        <% to = Enum.find(@graph.nodes, &(&1.id == e.to)) %>
        <%= if from && to do %>
          <line
            x1={from.x + 120}
            y1={from.y + box_height(from.label)}
            x2={to.x + 120}
            y2={to.y}
            stroke="#94a3b8"
            stroke-width="2"
            marker-end="url(#arrow)"
          />
        <% end %>
      <% end %>

      <!-- nodes -->
      <%= for n <- @graph.nodes do %>
        <% {badge, fill, stroke} = Map.get(DSL.colors(), n.type, {"", "#f1f3f5", "#495057"}) %>
        <% h = box_height(n.label) %>
        <% tx = if badge != "", do: n.x + 56, else: n.x + 8 %>
        <% tw = if badge != "", do: 176, else: 224 %>
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
            <rect x={n.x + 6} y={n.y + 6} width="44" height="18" rx="3" fill={stroke} />
            <text
              x={n.x + 28}
              y={n.y + 19}
              text-anchor="middle"
              font-size="10"
              font-family="monospace"
              font-weight="600"
              fill="#fff"
            ><%= badge %></text>
          <% end %>
          <foreignObject x={tx} y={n.y + 6} width={tw} height={h - 12}>
            <div xmlns="http://www.w3.org/1999/xhtml" style="font-size:14px;font-family:sans-serif;color:#1e1e1e;line-height:1.3;word-wrap:break-word;padding-left:0">
              <%= n.label %>
            </div>
          </foreignObject>
        </g>
      <% end %>

      <defs>
        <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
          <path d="M 0 0 L 10 5 L 0 10 z" fill="#94a3b8" />
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
    max_x = Enum.max(xs) + 260
    max_y = Enum.max(ys) + 100
    {min_x, min_y, max_x - min_x, max_y - min_y}
  end

  # Box height grows with label length. Text area is 176px (with badge) or 224px
  # (no badge) at 14px font — ~20 chars/line. 18px per line, min 44px.
  defp box_height(label) do
    lines = max(1, div(String.length(label), 20) + 1)
    max(44, lines * 18 + 14)
  end
end
