defmodule FlowspecOpsWeb.Factory.ShowLive do
  use FlowspecOpsWeb, :live_view

  alias FlowspecOps.Factories

  @tabs [
    {"Project Net", "net"},
    {"Build", "build"},
    {"Details", "details"}
  ]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    factory = Factories.get_factory!(id)

    {:ok,
     assign(socket,
       factory: factory,
       ungrouped_nodes: ungrouped_nodes(factory),
       tabs: @tabs,
       selected_tab: "net",
       page_title: factory.name,
       add_node_open: false,
       add_node_kind: "work_cell",
       add_node_name: "",
       add_node_line_id: nil,
       add_step_node_id: nil,
       add_step_name: "",
       commitment_edit_open: false
     )}
  end

  @impl true
  def handle_event("select_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, selected_tab: tab)}
  end

  @impl true
  def handle_event("open_commitment_edit", _params, socket) do
    {:noreply, assign(socket, commitment_edit_open: true)}
  end

  @impl true
  def handle_event("cancel_commitment_edit", _params, socket) do
    {:noreply, assign(socket, commitment_edit_open: false)}
  end

  @impl true
  def handle_event("save_commitment", params, socket) do
    attrs = %{
      target_qty: parse_optional_positive_int(Map.get(params, "target_qty")),
      window_days: parse_optional_positive_int(Map.get(params, "window_days"))
    }

    case Factories.update_factory(socket.assigns.factory, attrs) do
      {:ok, _factory} ->
        {:noreply, reload_factory(socket) |> assign(commitment_edit_open: false)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("open_add_node", _params, socket) do
    {:noreply, assign(socket, add_node_open: true, add_node_kind: "work_cell", add_node_name: "", add_node_line_id: nil)}
  end

  @impl true
  def handle_event("cancel_add_node", _params, socket) do
    {:noreply, assign(socket, add_node_open: false)}
  end

  @impl true
  def handle_event("add_node", params, socket) do
    factory = socket.assigns.factory
    kind = Map.get(params, "kind", "work_cell")
    name = Map.get(params, "name", "") |> String.trim()
    line_id = parse_optional_id(Map.get(params, "line_id", ""))

    group_nodes = Enum.filter(factory.nodes, fn n -> n.line_id == line_id end)

    next_pos =
      group_nodes
      |> Enum.sort_by(& &1.position)
      |> List.last()
      |> case do
        nil -> 1
        n -> n.position + 1
      end

    case Factories.create_node(%{
           factory_id: factory.id,
           kind: kind,
           name: name,
           position: next_pos,
           line_id: line_id
         }) do
      {:ok, _node} ->
        {:noreply, reload_factory(socket) |> assign(add_node_open: false)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_node", %{"id" => id}, socket) do
    node = Enum.find(socket.assigns.factory.nodes, &(to_string(&1.id) == id))

    if node do
      Factories.delete_node(node)
      {:noreply, reload_factory(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("move_node_up", %{"id" => id}, socket) do
    factory = socket.assigns.factory
    node = Enum.find(factory.nodes, &(to_string(&1.id) == id))
    if node, do: Factories.move_node_up(node, factory.nodes)
    {:noreply, reload_factory(socket)}
  end

  @impl true
  def handle_event("move_node_down", %{"id" => id}, socket) do
    factory = socket.assigns.factory
    node = Enum.find(factory.nodes, &(to_string(&1.id) == id))
    if node, do: Factories.move_node_down(node, factory.nodes)
    {:noreply, reload_factory(socket)}
  end

  @impl true
  def handle_event("open_add_step", %{"node_id" => node_id}, socket) do
    {:noreply, assign(socket, add_step_node_id: String.to_integer(node_id), add_step_name: "")}
  end

  @impl true
  def handle_event("cancel_add_step", _params, socket) do
    {:noreply, assign(socket, add_step_node_id: nil)}
  end

  @impl true
  def handle_event("add_step", %{"node_id" => node_id, "name" => name}, socket) do
    node_id_int = String.to_integer(node_id)
    node = Enum.find(socket.assigns.factory.nodes, &(&1.id == node_id_int))

    if node && node.kind == :work_cell do
      next_pos = length(node.steps) + 1

      case Factories.create_step(%{
             factory_node_id: node_id_int,
             name: String.trim(name),
             position: next_pos
           }) do
        {:ok, _step} ->
          {:noreply, reload_factory(socket) |> assign(add_step_node_id: nil)}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_step", %{"id" => id}, socket) do
    all_steps = socket.assigns.factory.nodes |> Enum.flat_map(& &1.steps)
    step = Enum.find(all_steps, &(to_string(&1.id) == id))

    if step do
      Factories.delete_step(step)
      {:noreply, reload_factory(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex flex-wrap items-end justify-between gap-2">
        <div>
          <h1 class="text-xl font-semibold text-zinc-900 dark:text-zinc-100"><%= @factory.name %></h1>
          <p class="text-sm text-zinc-500 dark:text-zinc-400"><%= @factory.client.name %></p>
        </div>
      </div>

      <.commitment_header factory={@factory} />

      <div class="px-0 pt-1">
        <div class="flex items-end gap-2">
          <%= for {label, value} <- @tabs do %>
            <button
              type="button"
              phx-click="select_tab"
              phx-value-tab={value}
              class={[
                "relative -mb-px rounded-t-md border px-4 py-2 text-xs font-semibold",
                @selected_tab == value &&
                  "z-10 border-zinc-200 border-b-0 bg-white text-zinc-900 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-100",
                @selected_tab != value &&
                  "mt-1 border-amber-200 bg-amber-100 text-amber-900 shadow-sm dark:border-zinc-700 dark:bg-zinc-900/60 dark:text-zinc-100"
              ]}
            >
              <%= label %>
            </button>
          <% end %>
        </div>
      </div>

      <div class={
        [
          "rounded-b-lg rounded-tr-lg border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-900",
          @selected_tab == "net" && "px-4 py-4",
          @selected_tab != "net" && "px-6 py-6"
        ]
      }>
        <%= case @selected_tab do %>
          <% "net" -> %>
            <.project_net
              lines={@factory.lines}
              ungrouped_nodes={@ungrouped_nodes}
              links={@factory.links}
              factory_lines={@factory.lines}
              add_node_open={@add_node_open}
              add_node_kind={@add_node_kind}
              add_node_name={@add_node_name}
              add_node_line_id={@add_node_line_id}
              add_step_node_id={@add_step_node_id}
              add_step_name={@add_step_name}
            />
          <% "build" -> %>
            <p class="text-sm text-zinc-500 dark:text-zinc-400">Build assignments will render here.</p>
          <% "details" -> %>
            <p class="text-sm text-zinc-500 dark:text-zinc-400">Factory details will render here.</p>
          <% _ -> %>
            <p class="text-sm text-zinc-500 dark:text-zinc-400">Select a tab.</p>
        <% end %>
      </div>

      <.commitment_edit_modal :if={@commitment_edit_open} factory={@factory} />
    </div>
    """
  end

  # --- Helpers ---

  defp reload_factory(socket) do
    factory = Factories.get_factory!(socket.assigns.factory.id)
    assign(socket, factory: factory, ungrouped_nodes: ungrouped_nodes(factory))
  end

  defp ungrouped_nodes(factory) do
    Enum.filter(factory.nodes, &is_nil(&1.line_id))
  end

  defp parse_optional_id(""), do: nil
  defp parse_optional_id(nil), do: nil
  defp parse_optional_id(str), do: String.to_integer(str)

  defp parse_optional_positive_int(nil), do: nil
  defp parse_optional_positive_int(""), do: nil

  defp parse_optional_positive_int(str) when is_binary(str) do
    case Integer.parse(String.trim(str)) do
      {n, ""} when n > 0 -> n
      _ -> nil
    end
  end

  defp parse_optional_positive_int(n) when is_integer(n) and n > 0, do: n
  defp parse_optional_positive_int(_), do: nil

  defp required_daily_rate(%{target_qty: qty, window_days: days})
       when is_integer(qty) and is_integer(days) and days > 0 do
    Float.round(qty / days * 1.0, 1)
  end

  defp required_daily_rate(_), do: nil

  defp commitment_header(assigns) do
    rate = required_daily_rate(assigns.factory)
    assigns = assign(assigns, :required_rate, rate)

    ~H"""
    <div class="sticky top-16 z-20 -mx-1 border border-zinc-200 bg-zinc-50/95 px-2.5 py-1 backdrop-blur dark:border-zinc-700 dark:bg-zinc-900/95">
      <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px] text-zinc-600 dark:text-zinc-300">
        <span class="font-semibold uppercase tracking-wide text-zinc-400 dark:text-zinc-500">Commitment</span>

        <span class="tabular-nums">
          <span class="text-zinc-400">Target</span>
          <span class="ml-1 font-semibold text-zinc-800 dark:text-zinc-100">
            <%= if @factory.target_qty, do: @factory.target_qty, else: "—" %>
          </span>
        </span>

        <span class="text-zinc-300 dark:text-zinc-600">·</span>

        <span class="tabular-nums">
          <span class="text-zinc-400">Window</span>
          <span class="ml-1 font-semibold text-zinc-800 dark:text-zinc-100">
            <%= if @factory.window_days, do: "#{@factory.window_days}d", else: "—" %>
          </span>
        </span>

        <span class="text-zinc-300 dark:text-zinc-600">·</span>

        <span class="tabular-nums">
          <span class="text-zinc-400">Need</span>
          <span class="ml-1 font-semibold text-zinc-800 dark:text-zinc-100">
            <%= if @required_rate, do: "#{@required_rate}/d", else: "—" %>
          </span>
        </span>

        <button
          type="button"
          phx-click="open_commitment_edit"
          class="ml-auto text-[10px] font-medium text-indigo-600 hover:text-indigo-500 dark:text-indigo-400"
        >
          Edit
        </button>
      </div>
    </div>
    """
  end

  defp commitment_edit_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-zinc-900/40" phx-click="cancel_commitment_edit"></div>
      <div class="relative w-full max-w-sm rounded-lg border border-zinc-200 bg-white p-4 shadow-xl dark:border-zinc-700 dark:bg-zinc-900">
        <h3 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">Commitment</h3>
        <p class="mt-0.5 text-[11px] text-zinc-500 dark:text-zinc-400">
          What this net is designed to satisfy.
        </p>

        <form phx-submit="save_commitment" class="mt-3 space-y-3">
          <label class="block">
            <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Target qty</span>
            <input
              type="number"
              name="target_qty"
              min="1"
              value={@factory.target_qty}
              class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
            />
          </label>

          <label class="block">
            <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Window (days)</span>
            <input
              type="number"
              name="window_days"
              min="1"
              value={@factory.window_days}
              class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
            />
          </label>

          <div class="flex items-center justify-end gap-2 pt-1">
            <button type="button" phx-click="cancel_commitment_edit" class="px-2 py-1 text-xs text-zinc-500 hover:text-zinc-700 dark:text-zinc-400">
              Cancel
            </button>
            <button type="submit" class="rounded bg-zinc-900 px-3 py-1 text-xs font-semibold text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900">
              Save
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  # --- Project Net ---

  defp project_net(assigns) do
    ~H"""
    <div class="space-y-4">
      <%= if Enum.empty?(@lines) && Enum.empty?(@ungrouped_nodes) do %>
        <p class="text-sm text-zinc-500 dark:text-zinc-400">No nodes yet. Add the first one below.</p>
      <% end %>

      <%= for line <- @lines do %>
        <.line_section line={line} add_step_node_id={@add_step_node_id} add_step_name={@add_step_name} />
      <% end %>

      <%= if @ungrouped_nodes != [] do %>
        <div class="space-y-2">
          <div class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400 dark:text-zinc-500">
            Ungrouped
          </div>
          <div class="flex flex-wrap items-start gap-4">
            <%= for node <- @ungrouped_nodes do %>
              <.node_card node={node} add_step_node_id={@add_step_node_id} add_step_name={@add_step_name} />
            <% end %>
          </div>
        </div>
      <% end %>

      <%= if @links != [] do %>
        <.links_summary links={@links} />
      <% end %>

      <%= if @add_node_open do %>
        <form phx-submit="add_node" class="flex flex-wrap items-center gap-2 rounded-none border border-zinc-300 bg-zinc-50 px-3 py-2 dark:border-zinc-700 dark:bg-zinc-800">
          <select name="kind" class="rounded border border-zinc-300 bg-white px-2 py-1 text-xs dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100">
            <option value="work_cell">Work Cell</option>
            <option value="queue">Queue</option>
            <option value="supplier">Supplier</option>
            <option value="transport">Transport</option>
          </select>
          <select name="line_id" class="rounded border border-zinc-300 bg-white px-2 py-1 text-xs dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100">
            <option value="">No line</option>
            <%= for line <- @factory_lines do %>
              <option value={line.id}><%= line.name %></option>
            <% end %>
          </select>
          <input
            type="text"
            name="name"
            placeholder="Node name"
            autofocus
            class="min-w-[12rem] flex-1 rounded border border-zinc-300 bg-white px-2 py-1 text-xs dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100"
          />
          <button type="submit" class="rounded bg-zinc-800 px-3 py-1 text-xs font-semibold text-white hover:bg-zinc-700 dark:bg-zinc-600 dark:hover:bg-zinc-500">
            Add
          </button>
          <button type="button" phx-click="cancel_add_node" class="text-xs text-zinc-500 hover:text-zinc-700 dark:text-zinc-400">
            Cancel
          </button>
        </form>
      <% else %>
        <button
          type="button"
          phx-click="open_add_node"
          class="rounded-none border border-dashed border-zinc-300 px-3 py-1.5 text-xs font-medium text-zinc-500 hover:border-zinc-400 hover:text-zinc-700 dark:border-zinc-700 dark:text-zinc-400 dark:hover:border-zinc-500"
        >
          + Add node
        </button>
      <% end %>
    </div>
    """
  end

  defp line_section(assigns) do
    sorted = Enum.sort_by(assigns.line.nodes, & &1.position)
    assigns = assign(assigns, sorted_nodes: sorted)

    ~H"""
    <div class="space-y-2">
      <div class="text-[10px] font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
        <%= @line.name %>
      </div>

      <div class="flex flex-wrap items-start gap-4">
        <%= for node <- @sorted_nodes do %>
          <.node_card node={node} add_step_node_id={@add_step_node_id} add_step_name={@add_step_name} />
        <% end %>
      </div>
    </div>
    """
  end

  # Pattern-matched dispatch by node kind
  defp node_card(%{node: %{kind: :supplier}} = assigns) do
    ~H"""
    <.supplier_card node={@node} />
    """
  end

  defp node_card(%{node: %{kind: :transport}} = assigns) do
    ~H"""
    <.transport_card node={@node} />
    """
  end

  defp node_card(%{node: %{kind: :queue}} = assigns) do
    ~H"""
    <.queue_card node={@node} />
    """
  end

  defp node_card(assigns) do
    ~H"""
    <.work_cell_card node={@node} add_step_node_id={@add_step_node_id} add_step_name={@add_step_name} />
    """
  end

  # --- Kind-specific cards (calijane2-shaped) ---

  defp supplier_card(assigns) do
    ~H"""
    <div class="w-full sm:w-[18rem] md:w-[18.5rem]">
      <div class="flex flex-col overflow-hidden rounded-none border border-zinc-200 bg-white text-xs dark:border-zinc-600 dark:bg-zinc-800">
        <div class="flex items-center gap-2 border-b border-green-300 bg-green-100 px-2.5 py-1.5 dark:border-green-700 dark:bg-green-900/30">
          <span class="inline-flex size-5 shrink-0 items-center justify-center rounded-full border border-green-400 text-[10px] font-bold tabular-nums text-green-800 dark:border-green-500 dark:text-green-200">
            <%= @node.position %>
          </span>
          <h4 class="min-w-0 truncate text-[10px] font-semibold uppercase tracking-wide text-zinc-900 dark:text-zinc-100">
            <%= @node.name %>
          </h4>
        </div>
        <div class="py-0.5">
          <%= if @node.location_note do %>
            <div class="px-2.5 py-1 text-[11px] text-zinc-500 dark:text-zinc-400"><%= @node.location_note %></div>
          <% end %>

          <div class="border-t border-dashed border-zinc-200 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-zinc-400 dark:border-zinc-600 dark:text-zinc-500">
            Setup
          </div>
          <div class="grid grid-cols-[minmax(0,1fr)_auto] gap-x-2 gap-y-0.5 px-2.5 pb-1.5 text-[11px] text-zinc-700 dark:text-zinc-200">
            <span class="text-zinc-500 dark:text-zinc-400">Factory setup</span>
            <span class="tabular-nums text-right">
              <%= if @node.setup_days, do: "#{@node.setup_days}d", else: "—" %>
            </span>
            <span class="text-zinc-500 dark:text-zinc-400">First batch</span>
            <span class="tabular-nums text-right">
              <%= cond do %>
                <% @node.first_batch_days && @node.first_batch_qty -> %>
                  <%= @node.first_batch_days %>d · qty <%= @node.first_batch_qty %>
                <% @node.first_batch_days -> %>
                  <%= @node.first_batch_days %>d
                <% @node.first_batch_qty -> %>
                  qty <%= @node.first_batch_qty %>
                <% true -> %>
                  —
              <% end %>
            </span>
            <span class="text-zinc-500 dark:text-zinc-400">Batch storage</span>
            <span class="tabular-nums text-right">
              <%= if @node.production_batch_slots, do: "#{@node.production_batch_slots} slots", else: "—" %>
            </span>
            <%= if @node.lead_time_days || @node.supply_cadence do %>
              <span class="text-zinc-500 dark:text-zinc-400">Cadence</span>
              <span class="tabular-nums text-right">
                <%= [@node.supply_cadence, @node.lead_time_days && "lead #{@node.lead_time_days}d"]
                    |> Enum.reject(&is_nil/1)
                    |> Enum.join(" · ") %>
              </span>
            <% end %>
          </div>

          <%= if @node.inspection_point do %>
            <div class="border-t border-zinc-100 px-2.5 py-1 text-[11px] text-amber-700 dark:border-zinc-700 dark:text-amber-300">
              Inspection gate
            </div>
          <% end %>
          <%= if @node.note do %>
            <p class="border-t border-zinc-100 px-2.5 py-1.5 text-[11px] leading-relaxed text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
              <%= @node.note %>
            </p>
          <% end %>
        </div>
        <div class="flex items-center justify-between border-t border-zinc-200 bg-zinc-50 px-2.5 py-1.5 text-xs text-zinc-700 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100">
          <span class="tabular-nums">
            <%= if @node.setup_days, do: "Setup #{@node.setup_days}d", else: "Supplier" %>
          </span>
          <button type="button" phx-click="delete_node" phx-value-id={@node.id} class="text-zinc-400 hover:text-red-500" title="Remove">×</button>
        </div>
      </div>
    </div>
    """
  end

  defp transport_card(assigns) do
    ship_label =
      case assigns.node.ship_weekday do
        nil -> nil
        day -> "Every #{String.capitalize(day)}"
      end

    transit_label =
      cond do
        assigns.node.transit_days -> "#{assigns.node.transit_days}d"
        assigns.node.transport_duration_minutes ->
          days = div(assigns.node.transport_duration_minutes, 24 * 60)
          if days > 0, do: "#{days}d", else: "#{assigns.node.transport_duration_minutes} min"

        true ->
          nil
      end

    assigns =
      assigns
      |> assign(:ship_label, ship_label)
      |> assign(:transit_label, transit_label)

    ~H"""
    <div class="w-full sm:w-[18rem] md:w-[18.5rem]">
      <div class="flex flex-col overflow-hidden rounded-none border border-zinc-200 bg-white text-xs dark:border-zinc-600 dark:bg-zinc-800">
        <div class="flex items-center gap-2 border-b border-amber-300 bg-amber-100 px-2.5 py-1.5 dark:border-amber-700 dark:bg-amber-900/30">
          <span class="inline-flex size-5 shrink-0 items-center justify-center rounded-full border border-amber-400 text-[10px] font-bold tabular-nums text-amber-800 dark:border-amber-500 dark:text-amber-200">
            <%= @node.position %>
          </span>
          <h4 class="min-w-0 truncate text-[10px] font-semibold uppercase tracking-wide text-zinc-900 dark:text-zinc-100">
            <%= @node.name %>
          </h4>
        </div>

        <div class="py-0.5">
          <%= if @node.vendor_name do %>
            <div class="px-2.5 py-1 text-[11px] text-zinc-500 dark:text-zinc-400">
              <%= @node.vendor_name %>
            </div>
          <% end %>

          <div class="border-t border-dashed border-zinc-200 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-zinc-400 dark:border-zinc-600 dark:text-zinc-500">
            Schedule
          </div>
          <div class="grid grid-cols-[minmax(0,1fr)_auto] gap-x-2 gap-y-0.5 px-2.5 pb-1.5 text-[11px] text-zinc-700 dark:text-zinc-200">
            <span class="text-zinc-500 dark:text-zinc-400">Route</span>
            <span class="text-right font-mono text-[10px]">
              <%= @node.from_location || "?" %> → <%= @node.to_location || "?" %>
            </span>
            <span class="text-zinc-500 dark:text-zinc-400">Transit</span>
            <span class="tabular-nums text-right"><%= @transit_label || "—" %></span>
            <span class="text-zinc-500 dark:text-zinc-400">Batch size</span>
            <span class="tabular-nums text-right">
              <%= if @node.batch_size, do: @node.batch_size, else: "—" %>
            </span>
            <span class="text-zinc-500 dark:text-zinc-400">Ship rule</span>
            <span class="tabular-nums text-right"><%= @ship_label || "—" %></span>
          </div>

          <%= if @node.batch_size && @ship_label do %>
            <div class="border-t border-zinc-100 px-2.5 py-1.5 text-[11px] text-zinc-600 dark:border-zinc-700 dark:text-zinc-300">
              Pickup <%= @node.batch_size %> frames · <%= String.downcase(@ship_label) %>
            </div>
          <% end %>
        </div>

        <div class="flex items-center justify-between border-t border-zinc-200 bg-zinc-50 px-2.5 py-1.5 text-xs text-zinc-700 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100">
          <span class="tabular-nums">
            <%= cond do %>
              <% @node.batch_size && @ship_label -> %>
                <%= @node.batch_size %>/wk
              <% true -> %>
                Transport
            <% end %>
          </span>
          <button type="button" phx-click="delete_node" phx-value-id={@node.id} class="text-zinc-400 hover:text-red-500" title="Remove">×</button>
        </div>
      </div>
    </div>
    """
  end

  defp queue_card(assigns) do
    role_label =
      case assigns.node.queue_role do
        :storage_lot -> "Storage lot"
        :feeding_buffer -> "Feeding buffer"
        _ -> "Queue"
      end

    assigns = assign(assigns, role_label: role_label)

    ~H"""
    <div class="w-full sm:w-[18rem] md:w-[18.5rem]">
      <div class="flex flex-col overflow-hidden rounded-none border border-zinc-200 bg-white text-xs dark:border-zinc-600 dark:bg-zinc-800">
        <div class="flex items-center gap-2 border-b border-sky-300 bg-sky-100 px-2.5 py-1.5 dark:border-sky-700 dark:bg-sky-900/30">
          <span class="inline-flex size-5 shrink-0 items-center justify-center rounded-full border border-sky-400 text-[10px] font-bold tabular-nums text-sky-800 dark:border-sky-500 dark:text-sky-200">
            <%= @node.position %>
          </span>
          <h4 class="min-w-0 truncate text-[10px] font-semibold uppercase tracking-wide text-zinc-900 dark:text-zinc-100">
            <%= @node.name %>
          </h4>
        </div>
        <div class="space-y-1 px-2.5 py-1.5 text-[11px] text-zinc-600 dark:text-zinc-300">
          <div class="tabular-nums">
            <%= @role_label %>
            <%= if @node.slots do %>
              · <%= @node.slots %> slots
            <% end %>
          </div>
          <%= if @node.note do %>
            <p class="leading-relaxed text-zinc-500 dark:text-zinc-400"><%= @node.note %></p>
          <% end %>
        </div>
        <div class="flex items-center justify-between border-t border-zinc-200 bg-zinc-50 px-2.5 py-1.5 text-xs text-zinc-700 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100">
          <span class="tabular-nums">
            <%= if @node.slots, do: "#{@node.slots} slots", else: "Queue" %>
          </span>
          <button type="button" phx-click="delete_node" phx-value-id={@node.id} class="text-zinc-400 hover:text-red-500" title="Remove">×</button>
        </div>
      </div>
    </div>
    """
  end

  defp work_cell_card(assigns) do
    est_total =
      assigns.node.steps
      |> Enum.map(& &1.estimated_minutes)
      |> Enum.reject(&is_nil/1)
      |> Enum.sum()

    assigns = assign(assigns, est_total: est_total)

    ~H"""
    <div class="w-full sm:w-[18rem] md:w-[18.5rem]">
      <div class="flex flex-col overflow-hidden rounded-none border border-zinc-200 bg-white text-xs dark:border-zinc-600 dark:bg-zinc-800">
        <%# header: line position + station name only; type via header color %>
        <div class="flex items-center gap-2 border-b border-zinc-300 bg-zinc-100 px-2.5 py-1.5 dark:border-zinc-500 dark:bg-zinc-700">
          <span class="inline-flex size-5 shrink-0 items-center justify-center rounded-full border border-zinc-400 text-[10px] font-bold tabular-nums text-zinc-900 dark:border-zinc-400 dark:text-zinc-100">
            <%= @node.position %>
          </span>
          <h4 class="min-w-0 truncate text-[10px] font-semibold uppercase tracking-wide text-zinc-900 dark:text-zinc-100">
            <%= @node.name %>
          </h4>
        </div>

        <%# step rows as a compact table %>
        <div class="py-0.5">
          <%= for step <- @node.steps do %>
            <div class="group/row grid grid-cols-[1.5rem_minmax(0,1fr)_3.5rem_1.5rem] items-center gap-1.5 px-2.5 py-1.5 text-xs hover:bg-zinc-50 dark:hover:bg-zinc-700/30">
              <span class="inline-flex size-5 items-center justify-center rounded-full border border-zinc-300 text-[10px] font-bold tabular-nums text-zinc-400 dark:border-zinc-500 dark:text-zinc-300">
                <%= step.position %>
              </span>
              <span class="min-w-0 truncate text-zinc-700 dark:text-zinc-200"><%= step.name %></span>
              <span class="text-right tabular-nums text-zinc-500 dark:text-zinc-300">
                <%= if step.estimated_minutes, do: "#{step.estimated_minutes}", else: "—" %>
              </span>
              <button
                type="button"
                phx-click="delete_step"
                phx-value-id={step.id}
                class="justify-self-end text-zinc-300 opacity-0 transition-opacity hover:text-red-500 group-hover/row:opacity-100 dark:text-zinc-600"
                title="Remove"
              >
                ×
              </button>
            </div>
          <% end %>

          <%= if @add_step_node_id == @node.id do %>
            <form phx-submit="add_step" class="flex items-center gap-2 border-t border-dashed border-zinc-200 px-2.5 py-1.5 dark:border-zinc-600">
              <input type="hidden" name="node_id" value={@node.id} />
              <input
                type="text"
                name="name"
                placeholder="Step name"
                autofocus
                class="min-w-0 flex-1 rounded border border-zinc-300 bg-white px-2 py-1 text-xs dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
              />
              <button type="submit" class="text-[10px] font-semibold text-indigo-600 dark:text-indigo-400">Add</button>
              <button type="button" phx-click="cancel_add_step" class="text-[10px] text-zinc-400">Cancel</button>
            </form>
          <% end %>
        </div>

        <%= if @add_step_node_id != @node.id do %>
          <button
            type="button"
            phx-click="open_add_step"
            phx-value-node_id={@node.id}
            class="w-full border-t border-dashed border-zinc-200 px-2.5 py-1 text-left text-[10px] text-zinc-400 transition-colors hover:bg-zinc-50 hover:text-indigo-500 dark:border-zinc-600 dark:text-zinc-500 dark:hover:bg-zinc-700/30 dark:hover:text-indigo-400"
          >
            + add step
          </button>
        <% end %>

        <%# footer: touches + est cycle time sum %>
        <div class="flex items-center justify-between border-t border-zinc-200 bg-zinc-50 px-2.5 py-1.5 text-xs text-zinc-700 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100">
          <span>
            Touches:
            <span class="font-semibold tabular-nums"><%= length(@node.steps) %></span>
            <%= if @node.slots do %>
              <span class="text-zinc-400 dark:text-zinc-400"> · <%= @node.slots %> slots</span>
            <% end %>
          </span>
          <span class="font-semibold tabular-nums">
            Est. CT: <%= if @est_total > 0, do: "#{@est_total}m", else: "—" %>
          </span>
        </div>
      </div>
    </div>
    """
  end

  defp links_summary(assigns) do
    ~H"""
    <div class="rounded-none border border-zinc-200 bg-zinc-50 px-2.5 py-2 dark:border-zinc-700 dark:bg-zinc-950">
      <h3 class="mb-2 text-[10px] font-semibold uppercase tracking-wide text-zinc-400 dark:text-zinc-500">Links</h3>
      <div class="space-y-1">
        <%= for link <- @links do %>
          <div class="flex flex-wrap items-center gap-2 text-xs text-zinc-600 dark:text-zinc-400">
            <span class="font-medium"><%= link.from_node.name %></span>
            <span class="text-zinc-300 dark:text-zinc-600">→</span>
            <span class="font-medium"><%= link.to_node.name %></span>
            <%= if link.label do %>
              <span class="text-[10px] text-zinc-500"><%= link.label %></span>
            <% end %>
            <%= if link.sku_filter do %>
              <span class="font-mono text-[10px] text-indigo-600 dark:text-indigo-400"><%= link.sku_filter %></span>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
