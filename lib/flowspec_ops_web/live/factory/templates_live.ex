defmodule FlowspecOpsWeb.Factory.TemplatesLive do
  use FlowspecOpsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Templates")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-2">
      <h1 class="text-xl font-semibold text-zinc-900 dark:text-zinc-100">Templates</h1>
      <p class="text-sm text-zinc-600 dark:text-zinc-300">
        Factory templates surface — placeholder.
      </p>
    </div>
    """
  end
end
