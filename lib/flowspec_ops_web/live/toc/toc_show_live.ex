defmodule FlowspecOpsWeb.TOC.TocShowLive do
  use FlowspecOpsWeb, :live_view

  alias FlowspecOps.TOC
  alias FlowspecOps.TOC.Diagram

  @topic "toc_diagram"

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    diagram = TOC.get_diagram!(id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(FlowspecOps.PubSub, @topic <> ":" <> id)
    end

    {:ok,
     socket
     |> assign(page_title: diagram.name, diagram: diagram, graph_json: diagram.graph_json)}
  end

  @impl true
  def handle_event("graph_changed", %{"graph" => graph}, socket) do
    diagram = socket.assigns.diagram

    case TOC.update_diagram(diagram, %{graph_json: graph}) do
      {:ok, updated} ->
        Phoenix.PubSub.broadcast(
          FlowspecOps.PubSub,
          @topic <> ":" <> diagram.id,
          {:graph_updated, updated.graph_json}
        )

        {:noreply, assign(socket, diagram: updated, graph_json: updated.graph_json)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:graph_updated, graph_json}, socket) do
    {:noreply, assign(socket, graph_json: graph_json)}
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
          <span>Drag to arrange · Auto-arrange button coming</span>
        </div>
      </div>

      <div
        id="toc-canvas"
        phx-hook="TocGraph"
        phx-update="ignore"
        data-graph={Jason.encode!(@graph_json)}
        class="h-[70vh] w-full rounded-lg border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-900"
      >
      </div>
    </div>
    """
  end
end
