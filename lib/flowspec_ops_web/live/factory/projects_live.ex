defmodule FlowspecOpsWeb.Factory.ProjectsLive do
  use FlowspecOpsWeb, :live_view

  alias FlowspecOps.Factories

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, factories: Factories.list_factories(), page_title: "Projects")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-3">
      <div>
        <h1 class="text-xl font-semibold text-zinc-900 dark:text-zinc-100">Projects</h1>
        <p class="text-sm text-zinc-600 dark:text-zinc-300">Factory projects.</p>
      </div>

      <div class="rounded-lg border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-900">
        <table class="w-full text-xs text-zinc-700 dark:text-zinc-200">
          <thead class="bg-zinc-50 dark:bg-zinc-950">
            <tr class="text-[11px] uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
              <th class="px-4 py-2 text-left">Factory</th>
              <th class="px-4 py-2 text-left">Client</th>
            </tr>
          </thead>
          <tbody>
            <%= if @factories == [] do %>
              <tr>
                <td colspan="2" class="px-4 py-6 text-center text-zinc-400 dark:text-zinc-500">No factories yet.</td>
              </tr>
            <% else %>
              <%= for factory <- @factories do %>
                <tr class="border-t border-zinc-200 dark:border-zinc-800 hover:bg-zinc-50 dark:hover:bg-zinc-800/50">
                  <td class="px-4 py-2">
                    <.link navigate={~p"/factory/projects/#{factory.id}"} class="font-semibold text-indigo-600 hover:underline dark:text-indigo-400">
                      <%= factory.name %>
                    </.link>
                  </td>
                  <td class="px-4 py-2 text-zinc-500 dark:text-zinc-400">
                    <%= factory.client.short_name || factory.client.name %>
                  </td>
                </tr>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
