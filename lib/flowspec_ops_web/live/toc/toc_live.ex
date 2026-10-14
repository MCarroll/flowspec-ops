defmodule FlowspecOpsWeb.TOC.TocLive do
  use FlowspecOpsWeb, :live_view

  alias FlowspecOps.TOC
  alias FlowspecOps.TOC.DSL

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "TOC Diagrams",
       diagrams: TOC.list_diagrams(),
       clouds_only: false,
       error: nil
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    clouds_only = socket.assigns.live_action == :clouds

    diagrams =
      if clouds_only do
        TOC.list_clouds()
      else
        TOC.list_trees()
      end

    {:noreply,
     assign(socket,
       page_title: if(clouds_only, do: "Clouds", else: "Diagrams"),
       diagrams: diagrams,
       clouds_only: clouds_only
     )}
  end

  @impl true
  def handle_event("create", %{"name" => name}, socket) do
    kind = if socket.assigns.clouds_only, do: "cloud", else: "tree"

    case TOC.create_diagram(%{name: name, kind: kind}) do
      {:ok, diagram} ->
        {:noreply, push_navigate(socket, to: ~p"/toc/#{diagram.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, error: "Could not create: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <h1 class="text-xl font-semibold text-zinc-900 dark:text-zinc-100">
          {@page_title}
          <%= if @clouds_only do %>
            <span class="ml-2 text-sm font-normal text-zinc-400">diagrams with a cloud</span>
          <% end %>
        </h1>
        <form phx-submit="create" class="flex gap-2">
          <input
            type="text"
            name="name"
            placeholder="New diagram name"
            class="rounded-md border border-zinc-300 px-3 py-1.5 text-sm dark:border-zinc-700 dark:bg-zinc-800"
          />
          <button
            type="submit"
            class="rounded-md bg-zinc-900 px-3 py-1.5 text-sm font-medium text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900"
          >
            Create
          </button>
        </form>
      </div>

      <%= if @error do %>
        <p class="text-sm text-red-600">{@error}</p>
      <% end %>

      <ul class="divide-y divide-zinc-200 dark:divide-zinc-800">
        <%= for d <- @diagrams do %>
          <li>
            <.link
              navigate={~p"/toc/#{d.id}"}
              class="flex items-center justify-between py-3 text-sm font-medium text-zinc-800 hover:text-zinc-600 dark:text-zinc-100 dark:hover:text-zinc-300"
            >
              <span>{d.name}</span>
              <span class="text-xs text-zinc-400">
                <%= if @clouds_only do %>
                  {length(TOC.list_versions(d.id))} versions
                <% else %>
                  {length(DSL.parse(d.dsl || "").nodes)} nodes
                <% end %>
              </span>
            </.link>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
