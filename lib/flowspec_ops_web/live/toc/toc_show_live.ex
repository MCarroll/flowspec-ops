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
     |> assign(page_title: diagram.name, diagram: diagram, dsl: diagram.dsl || "", graph: graph)}
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
        <div class="flex items-center gap-2 text-xs text-zinc-400">
          <span><%= length(@graph.nodes) %> nodes · <%= length(@graph.edges) %> edges</span>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <!-- Left: DSL editor -->
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

        <!-- Right: SVG render -->
        <div class="overflow-auto rounded-lg border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-900">
          <div class="border-b border-zinc-200 px-3 py-2 text-xs font-medium text-zinc-500 dark:border-zinc-800 dark:text-zinc-400">
            Render
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
    <svg viewBox="0 0 800 1200" class="w-full" xmlns="http://www.w3.org/2000/svg">
      <!-- edges -->
      <%= for e <- @graph.edges do %>
        <% from = Enum.find(@graph.nodes, &(&1.id == e.from)) %>
        <% to = Enum.find(@graph.nodes, &(&1.id == e.to)) %>
        <%= if from && to do %>
          <line
            x1={from.x + 120}
            y1={from.y + 40}
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
        <g>
          <rect
            x={n.x}
            y={n.y}
            width="240"
            height="80"
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
          <text
            x={n.x + 60}
            y={n.y + 30}
            font-size="12"
            font-family="sans-serif"
            fill="#1e1e1e"
          ><%= n.label %></text>
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
end
