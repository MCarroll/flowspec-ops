defmodule FlowspecOpsWeb.Factory.ShowLive do
  use FlowspecOpsWeb, :live_view

alias FlowspecOps.Factories
  alias FlowspecOps.Factories.FactoryNodeStep
  alias FlowspecOps.Factories.StationMath

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
       commitment_edit_open: false,
       commitment_edit_line_id: nil,
       step_edit_id: nil,
       station_edit_id: nil,
       transport_edit_id: nil,
versions: Factories.list_versions(factory.id),
       versions_open: false,
       save_version_open: false,
       restore_confirm_id: nil,
       card_menu_id: nil
     )}
  end

@impl true
  def handle_event("select_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, selected_tab: tab, card_menu_id: nil)}
  end

  @impl true
  def handle_event("toggle_card_menu", %{"id" => id}, socket) do
    next =
      if socket.assigns.card_menu_id == id do
        nil
      else
        id
      end

    {:noreply, assign(socket, card_menu_id: next)}
  end

  @impl true
  def handle_event("close_card_menu", _params, socket) do
    {:noreply, assign(socket, card_menu_id: nil)}
  end

  @impl true
  def handle_event("open_commitment_edit", params, socket) do
    {:noreply, assign(socket, commitment_edit_open: true, commitment_edit_line_id: parse_optional_id(Map.get(params, "mpl_id")))}
  end

  @impl true
def handle_event("cancel_commitment_edit", _params, socket) do
    {:noreply, assign(socket, commitment_edit_open: false)}
  end

  @impl true
  def handle_event("toggle_versions", _params, socket) do
    {:noreply, assign(socket, versions_open: !socket.assigns.versions_open, save_version_open: false, restore_confirm_id: nil)}
  end

  @impl true
  def handle_event("open_save_version", _params, socket) do
    {:noreply, assign(socket, save_version_open: true, versions_open: true, restore_confirm_id: nil)}
  end

  @impl true
  def handle_event("cancel_save_version", _params, socket) do
    {:noreply, assign(socket, save_version_open: false)}
  end

  @impl true
  def handle_event("save_version", params, socket) do
    name = params |> Map.get("name", "") |> String.trim()
    note = params |> Map.get("note", "") |> String.trim()

    case Factories.save_version(socket.assigns.factory, %{name: name, note: note}) do
      {:ok, version} ->
        {:noreply,
         socket
         |> assign(
           versions: Factories.list_versions(socket.assigns.factory.id),
           save_version_open: false,
           versions_open: true
         )
         |> put_flash(:info, "Milestone saved: #{version.name}")}

      {:error, :name_required} ->
        {:noreply, put_flash(socket, :error, "Milestone name required")}

      {:error, {:schema_parity, errors}} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "VERSION SCHEMA PARITY FAILED — milestone blocked. #{Enum.join(errors, "; ")}"
         )}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not save milestone: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("confirm_restore_version", %{"id" => id}, socket) do
    {:noreply, assign(socket, restore_confirm_id: String.to_integer(id), save_version_open: false)}
  end

  @impl true
  def handle_event("cancel_restore_version", _params, socket) do
    {:noreply, assign(socket, restore_confirm_id: nil)}
  end

  @impl true
  def handle_event("restore_version", %{"id" => id}, socket) do
    version_id = String.to_integer(id)

    case Factories.restore_version(socket.assigns.factory, version_id) do
      {:ok, %{version: version}} ->
        {:noreply,
         socket
         |> reload_factory()
         |> assign(
           versions: Factories.list_versions(socket.assigns.factory.id),
           restore_confirm_id: nil,
           versions_open: true
         )
         |> put_flash(:info, "Restored milestone: #{version.name}")}

      {:error, {:schema_parity, errors}} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "VERSION SCHEMA PARITY FAILED — restore blocked. #{Enum.join(errors, "; ")}"
         )}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Could not restore: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("save_commitment", params, socket) do
    mpl_id = parse_optional_id(Map.get(params, "mpl_id"))
    mpl = Enum.find(socket.assigns.factory.master_production_lines, &(&1.id == mpl_id))

    if mpl do
      attrs = %{
        target_qty: parse_optional_positive_int(Map.get(params, "target_qty")),
        window_days: parse_optional_positive_int(Map.get(params, "window_days")),
        start_date: parse_optional_date(Map.get(params, "start_date"))
      }

      case Factories.update_master_production_line(mpl, attrs) do
        {:ok, _mpl} ->
          {:noreply, reload_factory(socket) |> assign(commitment_edit_open: false)}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    else
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
  def handle_event("toggle_gate", %{"id" => id}, socket) do
    node = Enum.find(socket.assigns.factory.nodes, &(to_string(&1.id) == id))

    if node do
      case Factories.update_node(node, %{gate: !node.gate}) do
        {:ok, _} -> {:noreply, reload_factory(socket)}
        {:error, _} -> {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("open_step_edit", %{"id" => id}, socket) do
    {:noreply, assign(socket, step_edit_id: String.to_integer(id), station_edit_id: nil)}
  end

  @impl true
  def handle_event("cancel_step_edit", _params, socket) do
    {:noreply, assign(socket, step_edit_id: nil)}
  end

  @impl true
  def handle_event("save_step", params, socket) do
    step_id = String.to_integer(params["step_id"])
    all_steps = socket.assigns.factory.nodes |> Enum.flat_map(& &1.steps)
    step = Enum.find(all_steps, &(&1.id == step_id))

    if step do
      qty = parse_optional_positive_int(Map.get(params, "qty_per_unit"))
      each = parse_optional_positive_int(Map.get(params, "minutes_each"))
      people = parse_optional_positive_int(Map.get(params, "people"))

      est =
        cond do
          is_integer(qty) and is_integer(each) -> qty * each
          true -> parse_optional_positive_int(Map.get(params, "estimated_minutes"))
        end

      parallel_enabled = params |> Map.get("parallel_enabled", "") |> to_string()
      parallel_raw = params |> Map.get("parallel_with_step_id", "") |> to_string() |> String.trim()

      parallel_id =
        cond do
          parallel_enabled != "true" -> nil
          parallel_raw in ["", "none"] -> nil
          true ->
            case Integer.parse(parallel_raw) do
              {i, _} -> i
              :error -> nil
            end
        end

      parallel_id = if parallel_id == step_id, do: nil, else: parallel_id

      attrs = %{
        name: params |> Map.get("name", step.name) |> String.trim(),
        qty_per_unit: qty,
        minutes_each: each,
        people: people,
        estimated_minutes: est,
        specs: blank_to_nil(Map.get(params, "specs")),
        shared: checkbox_true?(params, "shared"),
        parallel_with_step_id: parallel_id
      }

      case Factories.update_step(step, attrs) do
        {:ok, _} ->
          # Keep popup open so cycle math updates live; Close dismisses.
          {:noreply, reload_factory(socket) |> assign(step_edit_id: step_id)}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("add_step_item", params, socket) do
    step_id = String.to_integer(params["step_id"])
    all_steps = socket.assigns.factory.nodes |> Enum.flat_map(& &1.steps)
    step = Enum.find(all_steps, &(&1.id == step_id))

    if step do
      name = params |> Map.get("name", "") |> String.trim()
      qty = parse_optional_positive_float(Map.get(params, "qty")) || 1.0
      cost = parse_money_to_cents(Map.get(params, "unit_cost"))
      kind = params |> Map.get("kind", "equipment") |> String.trim()

      kind_atom =
        case kind do
          "material" -> :material
          _ -> :equipment
        end

      if name != "" do
        next_pos = length(Map.get(step, :items) || []) + 1

        pack_qty = parse_optional_positive_float(Map.get(params, "pack_qty"))

        case Factories.create_step_item(%{
               factory_node_step_id: step.id,
               kind: kind_atom,
               name: name,
               qty: qty,
               unit_cost_cents: cost,
               pack_qty: if(kind_atom == :material, do: pack_qty, else: nil),
               position: next_pos,
               note: blank_to_nil(Map.get(params, "note"))
             }) do
          {:ok, _} -> {:noreply, reload_factory(socket)}
          {:error, _} -> {:noreply, socket}
        end
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_step_item", %{"id" => id}, socket) do
    all_items =
      socket.assigns.factory.nodes
      |> Enum.flat_map(& &1.steps)
      |> Enum.flat_map(fn s -> Map.get(s, :items) || [] end)

    item = Enum.find(all_items, &(to_string(&1.id) == id))

    if item do
      Factories.delete_step_item(item)
      {:noreply, reload_factory(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_step_item", params, socket) do
    item_id = params |> Map.get("item_id") || Map.get(params, "id")
    item_id = if is_binary(item_id), do: String.to_integer(item_id), else: item_id

    all_items =
      socket.assigns.factory.nodes
      |> Enum.flat_map(& &1.steps)
      |> Enum.flat_map(fn s -> Map.get(s, :items) || [] end)

    item = Enum.find(all_items, &(&1.id == item_id))

    if item do
      attrs = %{}

      attrs =
        if Map.has_key?(params, "name") do
          name = params["name"] |> to_string() |> String.trim()
          if name != "", do: Map.put(attrs, :name, name), else: attrs
        else
          attrs
        end

      attrs =
        if Map.has_key?(params, "qty") do
          case parse_optional_positive_float(params["qty"]) do
            nil -> attrs
            q -> Map.put(attrs, :qty, q)
          end
        else
          attrs
        end

      attrs =
        if Map.has_key?(params, "unit_cost") do
          Map.put(attrs, :unit_cost_cents, parse_money_to_cents(params["unit_cost"]))
        else
          attrs
        end

      attrs =
        if Map.has_key?(params, "kind") do
          kind =
            case params["kind"] do
              "material" -> :material
              _ -> :equipment
            end

          Map.put(attrs, :kind, kind)
        else
          attrs
        end

      attrs =
        if Map.has_key?(params, "pack_qty") do
          Map.put(attrs, :pack_qty, parse_optional_positive_float(params["pack_qty"]))
        else
          attrs
        end

      if attrs == %{} do
        {:noreply, socket}
      else
        case Factories.update_step_item(item, attrs) do
          {:ok, _} -> {:noreply, reload_factory(socket)}
          {:error, _} -> {:noreply, socket}
        end
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("open_transport_edit", %{"id" => id}, socket) do
    {:noreply, assign(socket, transport_edit_id: String.to_integer(id), step_edit_id: nil, station_edit_id: nil)}
  end

  @impl true
  def handle_event("cancel_transport_edit", _params, socket) do
    {:noreply, assign(socket, transport_edit_id: nil)}
  end

  @impl true
  def handle_event("save_transport", params, socket) do
    node_id = String.to_integer(params["node_id"])
    node = Enum.find(socket.assigns.factory.nodes, &(&1.id == node_id))

    if node do
      attrs = %{
        name: params |> Map.get("name", node.name) |> String.trim(),
        vendor_name: blank_to_nil(Map.get(params, "vendor_name")),
        from_location: blank_to_nil(Map.get(params, "from_location")),
        to_location: blank_to_nil(Map.get(params, "to_location")),
        batch_size: parse_optional_positive_int(Map.get(params, "batch_size")),
        ship_weekday: blank_to_nil(Map.get(params, "ship_weekday")),
        transit_days: parse_optional_positive_int(Map.get(params, "transit_days")),
        note: blank_to_nil(Map.get(params, "note"))
      }

      case Factories.update_node(node, attrs) do
        {:ok, _} ->
          {:noreply, reload_factory(socket) |> assign(transport_edit_id: nil)}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("open_station_edit", %{"id" => id}, socket) do
    {:noreply, assign(socket, station_edit_id: String.to_integer(id), step_edit_id: nil)}
  end

  @impl true
  def handle_event("cancel_station_edit", _params, socket) do
    {:noreply, assign(socket, station_edit_id: nil)}
  end

  @impl true
  def handle_event("save_station", params, socket) do
    node_id = String.to_integer(params["node_id"])
    node = Enum.find(socket.assigns.factory.nodes, &(&1.id == node_id))

    if node do
      attrs = %{
        name: params |> Map.get("name", node.name) |> String.trim(),
        slots: parse_optional_positive_int(Map.get(params, "slots")),
        note: blank_to_nil(Map.get(params, "note")),
        product_ready: checkbox_true?(params, "product_ready"),
        method_instruction: checkbox_true?(params, "method_instruction"),
        standup_weeks: parse_optional_positive_float(Map.get(params, "standup_weeks")),
        standup_people: parse_optional_positive_int(Map.get(params, "standup_people")),
        standup_source: parse_standup_source(Map.get(params, "standup_source")),
        standup_note: blank_to_nil(Map.get(params, "standup_note"))
      }

      case Factories.update_node(node, attrs) do
        {:ok, _} ->
          {:noreply, reload_factory(socket) |> assign(station_edit_id: nil)}

        {:error, _} ->
          {:noreply, socket}
      end
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
        <div class="flex items-center gap-2">
          <button
            type="button"
            phx-click="open_save_version"
            class="rounded bg-zinc-900 px-3 py-1.5 text-xs font-semibold text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900"
          >
            Save version
          </button>
          <button
            type="button"
            phx-click="toggle_versions"
            class="rounded border border-zinc-300 px-3 py-1.5 text-xs font-medium text-zinc-700 hover:bg-zinc-50 dark:border-zinc-600 dark:text-zinc-200 dark:hover:bg-zinc-800"
          >
            Milestones <%= if @versions != [], do: "(#{length(@versions)})", else: "" %>
          </button>
        </div>
      </div>

      <.versions_panel
        :if={@versions_open}
        versions={@versions}
        save_version_open={@save_version_open}
        restore_confirm_id={@restore_confirm_id}
      />



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
              factory={@factory}
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
              card_menu_id={@card_menu_id}
            />
          <% "build" -> %>
            <p class="text-sm text-zinc-500 dark:text-zinc-400">Build assignments will render here.</p>
          <% "details" -> %>
            <p class="text-sm text-zinc-500 dark:text-zinc-400">Factory details will render here.</p>
          <% _ -> %>
            <p class="text-sm text-zinc-500 dark:text-zinc-400">Select a tab.</p>
        <% end %>
      </div>

      <.commitment_edit_modal :if={@commitment_edit_open} factory={@factory} commitment_edit_line_id={@commitment_edit_line_id} />
      <.step_edit_modal
        :if={@step_edit_id}
        factory={@factory}
        step_edit_id={@step_edit_id}
      />
      <.station_edit_modal
        :if={@station_edit_id}
        factory={@factory}
        station_edit_id={@station_edit_id}
      />
      <.transport_edit_modal
        :if={@transport_edit_id}
        factory={@factory}
        transport_edit_id={@transport_edit_id}
      />
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

  defp parse_optional_date(nil), do: nil
  defp parse_optional_date(""), do: nil
  defp parse_optional_date(str) when is_binary(str) do
    case Date.from_iso8601(str) do
      {:ok, date} -> date
      _ -> nil
    end
  end
  defp parse_optional_date(%Date{} = date), do: date
  defp parse_optional_date(_), do: nil

  defp parse_optional_positive_float(nil), do: nil
  defp parse_optional_positive_float(""), do: nil

  defp parse_optional_positive_float(str) when is_binary(str) do
    cleaned =
      str
      |> String.trim()
      |> String.replace(",", "")

    # Allow ".25" as well as "0.25"
    cleaned =
      cond do
        String.starts_with?(cleaned, ".") -> "0" <> cleaned
        String.starts_with?(cleaned, "-.") -> "-0" <> String.trim_leading(cleaned, "-")
        true -> cleaned
      end

    case Float.parse(cleaned) do
      {f, rest} ->
        rest = String.trim(rest)

        cond do
          rest != "" -> nil
          f > 0 -> f
          true -> nil
        end

      :error ->
        case Integer.parse(cleaned) do
          {i, ""} when i > 0 -> i * 1.0
          _ -> nil
        end
    end
  end

  defp parse_optional_positive_float(n) when is_integer(n) and n > 0, do: n * 1.0
  defp parse_optional_positive_float(n) when is_float(n) and n > 0, do: n
  defp parse_optional_positive_float(_), do: nil

  defp parse_standup_source(nil), do: nil
  defp parse_standup_source(""), do: nil
  defp parse_standup_source("in_house"), do: :in_house
  defp parse_standup_source("subcontract"), do: :subcontract
  defp parse_standup_source("mixed"), do: :mixed
  defp parse_standup_source(_), do: nil

  defp standup_face_label(node) do
    parts =
      []
      |> then(fn acc ->
        case Map.get(node, :standup_weeks) do
          w when is_number(w) and w > 0 ->
            label =
              if is_float(w) and w == Float.floor(w) do
                "#{trunc(w)}w"
              else
                s = :erlang.float_to_binary(w * 1.0, decimals: 1) |> String.trim_trailing("0") |> String.trim_trailing(".")
                "#{s}w"
              end

            acc ++ [label]

          _ ->
            acc
        end
      end)
      |> then(fn acc ->
        case Map.get(node, :standup_people) do
          p when is_integer(p) and p > 0 -> acc ++ ["#{p} ppl"]
          _ -> acc
        end
      end)
      |> then(fn acc ->
        case Map.get(node, :standup_source) do
          :in_house -> acc ++ ["in-house"]
          :subcontract -> acc ++ ["sub"]
          :mixed -> acc ++ ["mixed"]
          _ -> acc
        end
      end)

    case parts do
      [] -> nil
      list -> Enum.join(list, " · ")
    end
  end

  defp format_qty_input(nil), do: ""
  defp format_qty_input(n) when is_integer(n), do: Integer.to_string(n)

  defp format_qty_input(n) when is_float(n) do
    # Avoid 0.25000000001 noise; keep useful decimals
    s = :erlang.float_to_binary(n, decimals: 6) |> String.trim_trailing("0") |> String.trim_trailing(".")
    if s == "" or s == "-0", do: "0", else: s
  end

  defp required_daily_rate(%{target_qty: qty, window_days: days})
       when is_integer(qty) and is_integer(days) and days > 0 do
    Float.round(qty / days * 1.0, 1)
  end

  defp required_daily_rate(_), do: nil

  defp required_weekly_rate(line), do: StationMath.required_weekly_rate(line)

  # If setup sits inside the commitment window, productive days shrink.
  defp required_weekly_rate_after_setup(%{target_qty: qty, window_days: window}, setup_days)
       when is_integer(qty) and is_integer(window) and is_integer(setup_days) and setup_days > 0 do
    productive = window - setup_days

    if productive > 0 do
      Float.round(qty * 7.0 / productive, 1)
    else
      nil
    end
  end

  defp required_weekly_rate_after_setup(_, _), do: nil

  # Prefer explicit supply cadence (e.g. "3 frames / week"); else 7/lead_time_days.
  defp designed_weekly_rate(node) do
    cond do
      match = cadence_weekly_rate(Map.get(node, :supply_cadence)) ->
        match

      is_integer(node.lead_time_days) and node.lead_time_days > 0 ->
        Float.round(7.0 / node.lead_time_days, 1)

      true ->
        nil
    end
  end

  defp cadence_weekly_rate(cadence) when is_binary(cadence) do
    cleaned = cadence |> String.downcase() |> String.trim()

    cond do
      Regex.match?(~r/per\s*week|\/\s*week|a\s*week|weekly/, cleaned) ->
        case Regex.run(~r/(\d+(?:\.\d+)?)/, cleaned) do
          [_, num] ->
            case Float.parse(num) do
              {f, _} when f > 0 -> Float.round(f, 1)
              _ -> nil
            end

          _ ->
            nil
        end

      true ->
        nil
    end
  end

  defp cadence_weekly_rate(_), do: nil

defp format_rate(v), do: StationMath.format_rate(v)

  defp supplier_vs_commitment(mpl, node) do
    need_wk = required_weekly_rate(mpl)
    need_after_setup = required_weekly_rate_after_setup(mpl, node.setup_days)
    have_wk = designed_weekly_rate(node)

    gap =
      if is_float(need_wk) and is_float(have_wk) do
        Float.round(need_wk - have_wk, 1)
      else
        nil
      end

    %{
      need_wk: need_wk,
      need_after_setup: need_after_setup,
      have_wk: have_wk,
      gap_wk: gap,
      short?: is_float(gap) and gap > 0
    }
  end

defp versions_panel(assigns) do
    ~H"""
    <div class="rounded-lg border border-zinc-200 bg-zinc-50 px-3 py-2 dark:border-zinc-700 dark:bg-zinc-900/80">
      <div class="flex flex-wrap items-center justify-between gap-2">
        <div class="text-[11px] font-semibold uppercase tracking-wide text-zinc-400">Milestones</div>
        <button
          type="button"
          phx-click="toggle_versions"
          class="text-[10px] text-zinc-500 hover:text-zinc-700 dark:text-zinc-400"
        >
          Close
        </button>
      </div>

      <%= if @save_version_open do %>
        <form phx-submit="save_version" class="mt-2 flex flex-wrap items-end gap-2 rounded border border-indigo-200 bg-white p-2 dark:border-indigo-900 dark:bg-zinc-900">
          <label class="min-w-[12rem] flex-1">
            <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Name</span>
            <input
              type="text"
              name="name"
              required
              placeholder="e.g. Pre-Reed workshop"
              class="mt-0.5 w-full rounded border border-zinc-300 bg-white px-2 py-1 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
            />
          </label>
          <label class="min-w-[12rem] flex-[2]">
            <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Note</span>
            <input
              type="text"
              name="note"
              placeholder="optional"
              class="mt-0.5 w-full rounded border border-zinc-300 bg-white px-2 py-1 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
            />
          </label>
          <button type="submit" class="rounded bg-zinc-900 px-3 py-1.5 text-xs font-semibold text-white dark:bg-zinc-100 dark:text-zinc-900">
            Create milestone
          </button>
          <button type="button" phx-click="cancel_save_version" class="px-2 py-1 text-xs text-zinc-500">
            Cancel
          </button>
        </form>
      <% end %>

      <%= if @versions == [] do %>
        <p class="mt-2 text-xs text-zinc-500 dark:text-zinc-400">No milestones yet. Save when you like where you are.</p>
      <% else %>
        <ul class="mt-2 divide-y divide-zinc-200 dark:divide-zinc-700">
          <%= for v <- @versions do %>
            <li class="flex flex-wrap items-center gap-2 py-1.5 text-xs">
              <div class="min-w-0 flex-1">
                <div class="font-medium text-zinc-800 dark:text-zinc-100">
                  <%= v.name %>
                  <%= if v.kind == "auto" do %>
                    <span class="ml-1 rounded bg-zinc-200 px-1 text-[9px] uppercase text-zinc-600 dark:bg-zinc-700 dark:text-zinc-300">auto</span>
                  <% end %>
                </div>
                <div class="text-[10px] tabular-nums text-zinc-400">
                  <%= Calendar.strftime(v.inserted_at, "%Y-%m-%d %H:%M") %>
                  <%= if v.note, do: " · #{v.note}", else: "" %>
                </div>
              </div>
              <%= if @restore_confirm_id == v.id do %>
                <span class="text-[10px] text-amber-700 dark:text-amber-300">Replace working copy? Current state auto-saved first.</span>
                <button
                  type="button"
                  phx-click="restore_version"
                  phx-value-id={v.id}
                  class="rounded bg-amber-600 px-2 py-1 text-[10px] font-semibold text-white hover:bg-amber-500"
                >
                  Restore
                </button>
                <button type="button" phx-click="cancel_restore_version" class="text-[10px] text-zinc-500">
                  Cancel
                </button>
              <% else %>
                <button
                  type="button"
                  phx-click="confirm_restore_version"
                  phx-value-id={v.id}
                  class="rounded border border-zinc-300 px-2 py-1 text-[10px] font-medium text-zinc-700 hover:bg-white dark:border-zinc-600 dark:text-zinc-200"
                >
                  Restore
                </button>
              <% end %>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  defp commitment_header(assigns) do
    rate = required_daily_rate(assigns.mpl)
    assigns = assign(assigns, :required_rate, rate)

    ~H"""
    <div class="border border-zinc-200 bg-zinc-50/95 px-2.5 py-1 dark:border-zinc-700 dark:bg-zinc-900/95">
      <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px] text-zinc-600 dark:text-zinc-300">
        <span class="font-semibold uppercase tracking-wide text-zinc-400 dark:text-zinc-500">Commitment</span>

        <span class="tabular-nums">
          <span class="text-zinc-400">Target</span>
          <span class="ml-1 font-semibold text-zinc-800 dark:text-zinc-100">
            <%= if @mpl && @mpl.target_qty, do: @mpl.target_qty, else: "—" %>
          </span>
        </span>

        <span class="text-zinc-300 dark:text-zinc-600">·</span>

        <span class="tabular-nums">
          <span class="text-zinc-400">Window</span>
          <span class="ml-1 font-semibold text-zinc-800 dark:text-zinc-100">
            <%= if @mpl && @mpl.window_days, do: "#{@mpl.window_days}d", else: "—" %>
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
          phx-value-mpl-id={@mpl && @mpl.id}
          class="ml-auto text-[10px] font-medium text-indigo-600 hover:text-indigo-500 dark:text-indigo-400"
        >
          Edit
        </button>
      </div>
    </div>
    """
  end

  defp commitment_edit_modal(assigns) do
    mpl = Enum.find(assigns.factory.master_production_lines, &(&1.id == assigns.commitment_edit_line_id))
    assigns = assign(assigns, :mpl, mpl)

    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-zinc-900/40" phx-click="cancel_commitment_edit"></div>
      <div class="relative w-full max-w-sm rounded-lg border border-zinc-200 bg-white p-4 shadow-xl dark:border-zinc-700 dark:bg-zinc-900">
        <h3 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">Commitment</h3>
        <p class="mt-0.5 text-[11px] text-zinc-500 dark:text-zinc-400">
          What this master production line is designed to satisfy.
        </p>

        <form phx-submit="save_commitment" class="mt-3 space-y-3">
          <input type="hidden" name="mpl_id" value={@mpl && @mpl.id} />

          <label class="block">
            <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Target qty</span>
            <input
              type="number"
              name="target_qty"
              min="1"
              value={@mpl && @mpl.target_qty}
              class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
            />
          </label>

          <label class="block">
            <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Window (days)</span>
            <input
              type="number"
              name="window_days"
              min="1"
              value={@mpl && @mpl.window_days}
              class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
            />
          </label>

          <label class="block">
            <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Start date</span>
            <input
              type="date"
              name="start_date"
              value={@mpl && @mpl.start_date}
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
    mpl = Enum.find(assigns.factory.master_production_lines, &(&1.id == assigns.line && assigns.line.master_production_line_id))
    assigns = assign(assigns, :mpl, mpl)

    ~H"""
    <div class="space-y-4">
      <%= if Enum.empty?(@lines) && Enum.empty?(@ungrouped_nodes) do %>
        <p class="text-sm text-zinc-500 dark:text-zinc-400">No nodes yet. Add the first one below.</p>
      <% end %>

      <.commitment_header mpl={@mpl} />

      <%= for line <- @lines do %>
        <.line_section
          factory={@factory}
          line={line}
          links={@links}
          all_nodes={@factory.nodes}
          add_step_node_id={@add_step_node_id}
          add_step_name={@add_step_name}
          card_menu_id={@card_menu_id}
        />
      <% end %>

      <%= if @ungrouped_nodes != [] do %>
        <div class="space-y-2">
          <div class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400 dark:text-zinc-500">
            Ungrouped
          </div>
          <div class="flex flex-wrap items-start gap-4">
            <%= for {node, seq} <- Enum.with_index(@ungrouped_nodes, 1) do %>
              <.node_card
                factory={@factory}
                node={node}
                sequence={seq}
                links={@links}
                add_step_node_id={@add_step_node_id}
                add_step_name={@add_step_name}
                card_menu_id={@card_menu_id}
              />
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
    display_items = line_display_items(sorted)
    spine = line_spine(sorted, assigns.links || [], assigns.all_nodes || [])
    mpl = Enum.find(assigns.factory.master_production_lines, &(&1.id == assigns.line.master_production_line_id))

    assigns =
      assigns
      |> assign(:sorted_nodes, sorted)
      |> assign(:display_items, display_items)
      |> assign(:spine, spine)
      |> assign(:mpl, mpl)

    ~H"""
    <div class="space-y-2">
      <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
        <div class="text-[10px] font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
          <%= @line.name %>
        </div>
        <%= if @spine != [] do %>
          <div class="flex min-w-0 flex-wrap items-center gap-1 text-[11px] text-zinc-600 dark:text-zinc-300">
            <%= for {seg, idx} <- Enum.with_index(@spine) do %>
              <%= if idx > 0 do %>
                <span class="text-zinc-300 dark:text-zinc-600">→</span>
              <% end %>
              <span class={
                [
                  "inline-flex items-center gap-1 rounded border px-1.5 py-0.5 font-medium tabular-nums",
                  seg.jump &&
                    "border-dashed border-indigo-300 bg-indigo-50 text-indigo-800 dark:border-indigo-700 dark:bg-indigo-950/40 dark:text-indigo-200",
                  !seg.jump &&
                    "border-zinc-200 bg-white dark:border-zinc-600 dark:bg-zinc-800"
                ]
              }>
                <span class="max-w-[9rem] truncate"><%= seg.name %></span>
                <%= if seg.mark do %>
                  <span class="text-[10px] font-semibold text-amber-700 dark:text-amber-300"><%= seg.mark %></span>
                <% end %>
              </span>
            <% end %>
          </div>
        <% end %>
      </div>

      <div class="flex flex-wrap items-start gap-4">
        <%= for {item, seq} <- Enum.with_index(@display_items, 1) do %>
          <%= case item do %>
            <% {:group, name, members} -> %>
              <.storage_group_card
                factory={@factory}
                name={name}
                members={members}
                sequence={seq}
                links={@links}
                line_nodes={@sorted_nodes}
                card_menu_id={@card_menu_id}
              />
            <% {:node, node} -> %>
              <.node_card
                factory={@factory}
                node={node}
                sequence={seq}
                links={@links}
                add_step_node_id={@add_step_node_id}
                add_step_name={@add_step_name}
                card_menu_id={@card_menu_id}
              />
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  # Collapse consecutive storage_group members into one display item.
  defp line_display_items(nodes) do
    nodes
    |> Enum.reduce([], fn node, acc ->
      group = node.storage_group

      case {group, acc} do
        {g, [{:group, g, members} | rest]} when is_binary(g) and g != "" ->
          [{:group, g, members ++ [node]} | rest]

        {g, _} when is_binary(g) and g != "" ->
          [{:group, g, [node]} | acc]

        _ ->
          [{:node, node} | acc]
      end
    end)
    |> Enum.reverse()
  end

  # Compact spine. Storage groups collapse to one chip with Σ slots.
  # Ends with ↓ target when the line hands off to another line.
  defp line_spine(nodes, links, all_nodes) when is_list(nodes) do
    line_ids = MapSet.new(Enum.map(nodes, & &1.id))

    segs =
      nodes
      |> line_display_items()
      |> Enum.map(fn
        {:group, name, members} ->
          total = members |> Enum.map(fn m -> m.slots || 0 end) |> Enum.sum()
          %{id: name, name: name, mark: "(#{total})", jump: false}

        {:node, node} ->
          mark =
            cond do
              node.kind == :transport && node.batch_size -> "×#{node.batch_size}"
              node.kind in [:work_cell, :queue] && node.slots -> "(#{node.slots})"
              true -> nil
            end

          %{id: node.id, name: node.name, mark: mark, jump: false}
      end)

    last = List.last(nodes)

    jump =
      if last do
        links
        |> Enum.filter(&(&1.from_node_id == last.id && &1.to_node))
        |> Enum.find(fn link -> not MapSet.member?(line_ids, link.to_node_id) end)
      else
        nil
      end

    case jump do
      %{to_node: to_node, label: label} ->
        mark =
          cond do
            is_binary(label) and label != "" -> label
            last.kind == :transport && last.batch_size -> "×#{last.batch_size}"
            true -> nil
          end

        # Prefer line name of target if we can resolve it from all_nodes (same node).
        _ = all_nodes

        segs ++ [%{id: to_node.id, name: "↓ #{to_node.name}", mark: mark, jump: true}]

      _ ->
        segs
    end
  end

  defp expected_weekly_in(node, links) do
    inbound_transport_links(node, links)
    |> Enum.map(fn l -> l.from_node.batch_size || 0 end)
    |> Enum.sum()
    |> case do
      0 -> nil
      n -> n
    end
  end

  # Compact door pattern from linked transport cards, e.g. "3Th+3Fr=6/wk".
  defp inbound_avail_label(node, links) do
    transports =
      inbound_transport_links(node, links)
      |> Enum.map(& &1.from_node)

    parts =
      transports
      |> Enum.map(fn t ->
        qty = t.batch_size
        day = t.ship_weekday && ship_day_short(t.ship_weekday)

        cond do
          qty && day -> "#{qty}#{day}"
          qty -> "#{qty}"
          true -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    total =
      transports
      |> Enum.map(fn t -> t.batch_size || 0 end)
      |> Enum.sum()

    cond do
      parts != [] and total > 0 -> Enum.join(parts, "+") <> "=#{total}/wk"
      total > 0 -> "#{total}/wk"
      true -> nil
    end
  end

  defp inbound_transport_links(node, links) do
    Enum.filter(links, &(&1.to_node_id == node.id && &1.from_node && &1.from_node.kind == :transport))
  end

  defp ship_day_short(day) when is_binary(day) do
    day
    |> String.trim()
    |> String.downcase()
    |> case do
      "monday" -> "Mo"
      "tuesday" -> "Tu"
      "wednesday" -> "We"
      "thursday" -> "Th"
      "friday" -> "Fr"
      "saturday" -> "Sa"
      "sunday" -> "Su"
      other -> other |> String.slice(0, 2) |> String.capitalize()
    end
  end

  defp ship_day_short(_), do: nil

  defp peak_step_people(steps) do
    steps
    |> Enum.map(& &1.people)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      list -> Enum.max(list)
    end
  end

  # Pattern-matched dispatch by node kind
  defp node_card(%{node: %{kind: :supplier}} = assigns) do
    ~H"""
    <.supplier_card factory={@factory} node={@node} sequence={@sequence} />
    """
  end

  defp node_card(%{node: %{kind: :transport}} = assigns) do
    ~H"""
    <.transport_card node={@node} sequence={@sequence} />
    """
  end

  defp node_card(%{node: %{kind: :queue}} = assigns) do
    ~H"""
    <.queue_card
      factory={@factory}
      node={@node}
      sequence={@sequence}
      links={@links}
      card_menu_id={@card_menu_id}
    />
    """
  end

  defp node_card(%{node: %{kind: :movement}} = assigns) do
    ~H"""
    <.movement_card
      factory={@factory}
      node={@node}
      sequence={@sequence}
      links={@links}
      add_step_node_id={@add_step_node_id}
      add_step_name={@add_step_name}
      card_menu_id={@card_menu_id}
    />
    """
  end

defp node_card(assigns) do
    ~H"""
    <.work_cell_card
      factory={@factory}
      node={@node}
      sequence={@sequence}
      links={@links}
      add_step_node_id={@add_step_node_id}
      add_step_name={@add_step_name}
      card_menu_id={@card_menu_id}
    />
    """
  end

  # --- Kind-specific cards (calijane2-shaped) ---

  defp supplier_card(assigns) do
    mpl = Enum.find(assigns.factory.master_production_lines, &(&1.id == assigns.node.line && assigns.node.line.master_production_line_id))
    vs = supplier_vs_commitment(mpl, assigns.node)
    assigns = assign(assigns, :vs, vs)

    ~H"""
    <div class="w-full sm:w-[18rem] md:w-[18.5rem]">
      <div class="flex flex-col overflow-hidden rounded-none border border-zinc-200 bg-white text-xs dark:border-zinc-600 dark:bg-zinc-800">
        <div class="flex items-center gap-2 border-b border-green-300 bg-green-100 px-2.5 py-1.5 dark:border-green-700 dark:bg-green-900/30">
          <span class="inline-flex size-5 shrink-0 items-center justify-center rounded-full border border-green-400 text-[10px] font-bold tabular-nums text-green-800 dark:border-green-500 dark:text-green-200">
            <%= @sequence || @node.position %>
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

          <div class="border-t border-dashed border-zinc-200 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-zinc-400 dark:border-zinc-600 dark:text-zinc-500">
            vs commitment
          </div>
          <div class="grid grid-cols-[minmax(0,1fr)_auto] gap-x-2 gap-y-0.5 px-2.5 pb-1.5 text-[11px] text-zinc-700 dark:text-zinc-200">
            <span class="text-zinc-500 dark:text-zinc-400">Need</span>
            <span class="tabular-nums text-right">
              <%= if @vs.need_wk, do: "#{format_rate(@vs.need_wk)}/wk", else: "—" %>
            </span>
            <%= if @vs.need_after_setup do %>
              <span class="text-zinc-500 dark:text-zinc-400">Need after setup</span>
              <span class="tabular-nums text-right" title="If setup sits inside the window">
                <%= format_rate(@vs.need_after_setup) %>/wk
              </span>
            <% end %>
            <span class="text-zinc-500 dark:text-zinc-400">Designed</span>
            <span class="tabular-nums text-right">
              <%= if @vs.have_wk, do: "#{format_rate(@vs.have_wk)}/wk", else: "—" %>
            </span>
            <span class="text-zinc-500 dark:text-zinc-400">Gap</span>
            <span class={
              [
                "tabular-nums text-right font-semibold",
                @vs.short? && "text-amber-700 dark:text-amber-300",
                !@vs.short? && @vs.gap_wk && "text-emerald-700 dark:text-emerald-300"
              ]
            }>
              <%= cond do %>
                <% is_nil(@vs.gap_wk) -> %>
                  —
                <% @vs.short? -> %>
                  short <%= format_rate(@vs.gap_wk) %>/wk
                <% @vs.gap_wk < 0 -> %>
                  headroom <%= format_rate(abs(@vs.gap_wk)) %>/wk
                <% true -> %>
                  matched
              <% end %>
            </span>
          </div>

          <%= if @vs.short? do %>
            <div class="border-t border-zinc-100 px-2.5 py-1 text-[10px] leading-snug text-zinc-500 dark:border-zinc-700 dark:text-zinc-400">
              Design cannot cover commitment at this cadence. Elevate supply rate or change the promise.
            </div>
          <% end %>

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
            <%= cond do %>
              <% @vs.have_wk && @vs.need_wk -> %>
                <%= format_rate(@vs.have_wk) %>/wk vs <%= format_rate(@vs.need_wk) %>
              <% @node.setup_days -> %>
                Setup <%= @node.setup_days %>d
              <% true -> %>
                Supplier
            <% end %>
          </span>
          <button type="button" phx-click="delete_node" phx-value-id={@node.id} data-confirm={"Remove #{@node.name}? This cannot be undone."} class="text-zinc-400 hover:text-red-500" title="Remove">×</button>
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
            <%= @sequence || @node.position %>
          </span>
          <button
            type="button"
            phx-click="open_transport_edit"
            phx-value-id={@node.id}
            class="min-w-0 flex-1 truncate text-left text-[10px] font-semibold uppercase tracking-wide text-zinc-900 hover:text-indigo-600 dark:text-zinc-100 dark:hover:text-indigo-300"
            title="Edit transport"
          >
            <%= @node.name %>
          </button>
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
          <button type="button" phx-click="delete_node" phx-value-id={@node.id} data-confirm={"Remove #{@node.name}? This cannot be undone."} class="text-zinc-400 hover:text-red-500" title="Remove">×</button>
        </div>
      </div>
    </div>
    """
  end

  defp movement_card(assigns) do
    steps = assigns.node.steps || []
    step_stats = Enum.map(steps, &StationMath.step_stat/1)

    content_total =
      step_stats
      |> Enum.map(& &1.content)
      |> Enum.reject(&is_nil/1)
      |> Enum.sum()
      |> case do
        0 -> 0
        n -> n
      end

    {ea_parallel, ea_phased, crew_designed, peak_phase} =
      StationMath.step_timing_summary(steps, step_stats)

    step_stats = annotate_parallel_rails(steps, step_stats)

    all_items =
      steps
      |> Enum.flat_map(fn s -> Map.get(s, :items) || [] end)

    stand_up_cents =
      all_items
      |> Enum.map(&FlowspecOps.Factories.FactoryNodeStepItem.stand_up_cents/1)
      |> Enum.reject(&is_nil/1)
      |> case do
        [] -> nil
        list -> Enum.sum(list)
      end

    burn_unit_cents =
      all_items
      |> Enum.map(&FlowspecOps.Factories.FactoryNodeStepItem.burn_per_unit_cents/1)
      |> Enum.reject(&is_nil/1)
      |> case do
        [] -> nil
        list -> Enum.sum(list)
      end

    slots = assigns.node.slots

    burn_batch_cents =
      cond do
        is_integer(burn_unit_cents) and is_integer(slots) and slots > 0 ->
          burn_unit_cents * slots

        true ->
          nil
      end

    links = assigns[:links] || []
    factory = assigns[:factory]
    expected_in = expected_weekly_in(assigns.node, links)
    mpl = Enum.find(assigns.factory.master_production_lines, &(&1.id == assigns.node.line && assigns.node.line.master_production_line_id))
    need_wk = mpl && StationMath.required_weekly_rate(mpl)
    avail_label = inbound_avail_label(assigns.node, links)
    crew = crew_designed
    gate? = Map.get(assigns.node, :gate) == true
    menu_open? = assigns[:card_menu_id] == "n-#{assigns.node.id}"

    gap =
      if is_number(expected_in) and is_float(need_wk) do
        Float.round(need_wk - expected_in * 1.0, 1)
      else
        nil
      end

    batch_cycle_min =
      cond do
        is_integer(slots) and slots > 0 and is_integer(ea_parallel) and ea_parallel > 0 ->
          slots * ea_parallel

        true ->
          nil
      end

    {rate_d, rate_w, rate_m} =
      StationMath.station_dwm_rates(if(ea_parallel > 0, do: ea_parallel, else: nil))

    rate_gap =
      if is_float(need_wk) and is_float(rate_w) do
        Float.round(need_wk - rate_w, 1)
      else
        nil
      end

    rate_gap_short? = is_float(rate_gap) and rate_gap > 0
    intake_short? = is_float(gap) and gap > 0

    status_circle =
      work_cell_status_circle(steps, content_total, ea_parallel, rate_gap_short? or intake_short?)

    assigns =
      assigns
      |> assign(:steps, steps)
      |> assign(:step_stats, step_stats)
      |> assign(:ea_parallel, ea_parallel)
      |> assign(:ea_phased, ea_phased)
      |> assign(:crew_designed, crew_designed)
      |> assign(:peak_phase, peak_phase)
      |> assign(:content_total, content_total)
      |> assign(:stand_up_cents, stand_up_cents)
      |> assign(:burn_unit_cents, burn_unit_cents)
      |> assign(:burn_batch_cents, burn_batch_cents)
      |> assign(:slots, slots)
      |> assign(:expected_in, expected_in)
      |> assign(:need_wk, need_wk)
      |> assign(:avail_label, avail_label)
      |> assign(:gap, gap)
      |> assign(:batch_cycle_min, batch_cycle_min)
      |> assign(:rate_d, rate_d)
      |> assign(:rate_w, rate_w)
      |> assign(:rate_m, rate_m)
      |> assign(:rate_gap, rate_gap)
      |> assign(:rate_gap_short?, rate_gap_short?)
      |> assign(:intake_short?, intake_short?)
      |> assign(:status_circle, status_circle)
      |> assign(:gate?, gate?)
      |> assign(:menu_open?, menu_open?)

    ~H"""
    <div class="w-full sm:w-[18rem] md:w-[18.5rem]">
      <div class="flex flex-col overflow-hidden rounded-none border border-zinc-200 bg-white text-xs dark:border-zinc-600 dark:bg-zinc-800">
        <div class="relative flex items-center gap-2 border-b border-violet-300 bg-violet-100 px-2.5 py-1.5 dark:border-violet-700 dark:bg-violet-900/30">
          <span class="inline-flex size-5 shrink-0 items-center justify-center rounded-full border border-violet-400 text-[10px] font-bold tabular-nums text-violet-800 dark:border-violet-500 dark:text-violet-200">
            <%= @sequence || @node.position %>
          </span>
          <h4 class="min-w-0 flex-1 truncate text-[10px] font-semibold uppercase tracking-wide text-zinc-900 dark:text-zinc-100">
            <%= @node.name %>
          </h4>
          <div class="relative shrink-0">
            <button
              type="button"
              phx-click="toggle_card_menu"
              phx-value-id={"n-#{@node.id}"}
              class="inline-flex h-5 w-5 items-center justify-center rounded text-violet-700 hover:bg-violet-200 hover:text-violet-950 dark:text-violet-200 dark:hover:bg-violet-800"
              title="Card menu"
              aria-label="Card menu"
              aria-expanded={to_string(@menu_open?)}
            >
              <span class="text-[14px] leading-none tracking-tighter" aria-hidden="true">⋮</span>
            </button>
            <%= if @menu_open? do %>
              <div
                class="absolute right-0 z-30 mt-1 w-44 overflow-hidden rounded border border-zinc-200 bg-white py-1 shadow-lg dark:border-zinc-600 dark:bg-zinc-800"
                role="menu"
              >
                <button
                  type="button"
                  phx-click="open_movement_edit"
                  phx-value-id={@node.id}
                  class="block w-full px-3 py-1.5 text-left text-[11px] font-medium text-zinc-800 hover:bg-zinc-100 dark:text-zinc-100 dark:hover:bg-zinc-700"
                  role="menuitem"
                >
                  Edit movement
                </button>
                <a
                  href={~p"/factory/projects/#{@factory.id}/nodes/#{@node.id}/pencil?seq=#{@sequence || @node.position}"}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="block px-3 py-1.5 text-left text-[11px] font-medium text-zinc-800 hover:bg-zinc-100 dark:text-zinc-100 dark:hover:bg-zinc-700"
                  role="menuitem"
                  data-phx-link="false"
                >
                  Print pencil sheet
                </a>
              </div>
            <% end %>
          </div>
        </div>
        <div class="space-y-1 px-2.5 py-1.5 text-[11px] text-zinc-600 dark:text-zinc-300">
          <div class="tabular-nums">
            Movement
            <%= if @node.slots do %>
              · <%= @node.slots %> slot<%= if @node.slots != 1, do: "s" %>
            <% end %>
            <%= if @node.qty_in_circulation do %>
              · <%= @node.qty_in_circulation %> in circulation
            <% end %>
            <%= if @node.trips_per_day do %>
              · <%= @node.trips_per_day %> trips/d
            <% end %>
            <%= if @node.duration_minutes do %>
              · <%= @node.duration_minutes %> min
            <% end %>
            <%= if @node.operator_count do %>
              · <%= @node.operator_count %> operators
            <% end %>
          </div>
          <%= if @node.from_location || @node.to_location do %>
            <div class="font-mono text-[10px] text-zinc-500 dark:text-zinc-400">
              <%= @node.from_location || "?" %> → <%= @node.to_location || "?" %>
            </div>
          <% end %>
          <%= if @node.note do %>
            <p class="leading-relaxed text-zinc-500 dark:text-zinc-400"><%= @node.note %></p>
          <% end %>
        </div>
        <%= if @steps != [] do %>
          <div class="border-t border-zinc-200 px-2.5 py-1.5 dark:border-zinc-600">
            <div class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400 dark:text-zinc-500">
              Steps
            </div>
            <%= for stat <- @step_stats do %>
              <% step = stat.step %>
              <div class="grid grid-cols-[1.5rem_minmax(0,1fr)_2rem] gap-1.5 py-1 text-xs">
                <span class="mt-0.5 inline-flex size-5 items-center justify-center rounded-full border border-zinc-300 text-[10px] font-bold tabular-nums text-zinc-500 dark:border-zinc-600">
                  <%= step.position %>
                </span>
                <div class="min-w-0">
                  <div class="truncate font-medium text-zinc-800 dark:text-zinc-100"><%= step.name %></div>
                  <%= if step.people do %>
                    <div class="text-[10px] tabular-nums text-zinc-400"><%= step.people %> ppl</div>
                  <% end %>
                  <%= for line <- spec_lines(step.specs) do %>
                    <div class="text-[10px] text-zinc-400"><%= line %></div>
                  <% end %>
                </div>
                <span class="pt-0.5 text-right tabular-nums text-zinc-500">
                  <%= if stat.content, do: "#{stat.content}m", else: "" %>
                </span>
              </div>
            <% end %>
          </div>
        <% end %>
        <div class="flex items-center justify-between border-t border-zinc-200 bg-zinc-50 px-2.5 py-1.5 text-xs text-zinc-700 dark:border-zinc-600 dark:bg-zinc-700 dark:text-zinc-100">
          <span class="tabular-nums">
            <%= if @node.slots, do: "#{@node.slots} slot/trip", else: "Movement" %>
            <%= if @node.qty_in_circulation do %>
              · <%= @node.qty_in_circulation %> carts
            <% end %>
          </span>
          <button type="button" phx-click="delete_node" phx-value-id={@node.id} data-confirm={"Remove #{@node.name}? This cannot be undone."} class="text-zinc-400 hover:text-red-500" title="Remove">×</button>
        </div>
      </div>
    </div>
    """
  end

  defp storage_group_card(assigns) do
    members = Enum.sort_by(assigns.members, & &1.position)

    total =
      members
      |> Enum.map(fn m -> m.slots || 0 end)
      |> Enum.sum()

    # Method steps live on the first lot node (group method).
    steps =
      members
      |> List.first()
      |> case do
        nil -> []
        lot -> lot.steps || []
      end
      |> Enum.sort_by(& &1.position)

    flooring =
      (assigns[:line_nodes] || [])
      |> Enum.find(&(&1.name == "Flooring"))

    pass_mark =
      cond do
        flooring && flooring.slots -> "(#{flooring.slots})"
        true -> nil
      end

    factory = assigns[:factory]
    menu_id = "g-#{assigns.name}"
    menu_open? = assigns[:card_menu_id] == menu_id

    pencil_href =
      if factory do
        ~p"/factory/projects/#{factory.id}/storage-groups/#{assigns.name}/pencil?seq=#{assigns.sequence}"
      else
        "#"
      end

    assigns =
      assigns
      |> assign(:total, total)
      |> assign(:members, members)
      |> assign(:steps, steps)
      |> assign(:pass_mark, pass_mark)
      |> assign(:menu_id, menu_id)
      |> assign(:menu_open?, menu_open?)
      |> assign(:pencil_href, pencil_href)

    ~H"""
    <div class="w-full sm:w-[18rem] md:w-[18.5rem]">
      <div class="flex flex-col overflow-hidden rounded-none border border-zinc-600 bg-white text-xs dark:border-zinc-600 dark:bg-zinc-800">
        <div class="relative flex items-center gap-2 border-b border-sky-400/80 bg-sky-950 px-2.5 py-1.5 text-sky-50 dark:border-sky-600 dark:bg-sky-950">
          <span class="inline-flex size-5 shrink-0 items-center justify-center rounded-full border border-sky-300 text-[10px] font-bold tabular-nums text-sky-100">
            <%= @sequence %>
          </span>
          <h4 class="min-w-0 truncate text-[10px] font-semibold uppercase tracking-wide">
            <%= @name %> LOT
          </h4>
          <span class="ml-auto shrink-0 tabular-nums text-[10px] font-semibold text-sky-100">
            <%= @total %>
          </span>
          <div class="relative shrink-0">
            <button
              type="button"
              phx-click="toggle_card_menu"
              phx-value-id={@menu_id}
              class="inline-flex h-5 w-5 items-center justify-center rounded text-sky-200 hover:bg-sky-900 hover:text-white"
              title="Card menu"
              aria-label="Card menu"
              aria-expanded={to_string(@menu_open?)}
            >
              <span class="text-[14px] leading-none tracking-tighter" aria-hidden="true">⋮</span>
            </button>
            <%= if @menu_open? do %>
              <div
                class="absolute right-0 z-30 mt-1 w-44 overflow-hidden rounded border border-zinc-200 bg-white py-1 shadow-lg dark:border-zinc-600 dark:bg-zinc-800"
                role="menu"
              >
<a
                  href={@pencil_href}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="block px-3 py-1.5 text-left text-[11px] font-medium text-zinc-800 hover:bg-zinc-100 dark:text-zinc-100 dark:hover:bg-zinc-700"
                  role="menuitem"
                  data-phx-link="false"
                >
                  Print pencil sheet
                </a>
              </div>
            <% end %>
          </div>
        </div>

        <div class="divide-y divide-zinc-700/80 bg-zinc-900 text-zinc-100">
          <div class="grid grid-cols-[minmax(0,1fr)_auto] gap-x-2 px-2.5 py-1.5 text-[11px]">
            <div class="font-medium text-zinc-200">Passthrough</div>
            <div class="tabular-nums text-right text-zinc-300">
              → <%= if @pass_mark, do: "#{@pass_mark} ", else: "" %>Flooring
            </div>
          </div>

          <%= for lot <- @members do %>
            <div class="grid grid-cols-[minmax(0,1fr)_auto] gap-x-2 px-2.5 py-1.5 text-[11px]">
              <div class="min-w-0">
                <div class="truncate font-medium"><%= lot.name %></div>
                <%= if lot.location_note do %>
                  <div class="text-[10px] text-zinc-400"><%= lot.location_note %></div>
                <% end %>
              </div>
              <div class="tabular-nums text-right font-semibold">
                <%= lot.slots || "—" %>
              </div>
            </div>
          <% end %>
        </div>

        <%= if @steps != [] do %>
          <div class="border-t border-zinc-700 bg-zinc-950 py-0.5 text-zinc-100">
            <%= for step <- @steps do %>
              <div class="grid grid-cols-[1.5rem_minmax(0,1fr)_2rem] gap-1.5 px-2.5 py-1.5 text-xs">
                <span class="mt-0.5 inline-flex size-5 items-center justify-center rounded-full border border-zinc-600 text-[10px] font-bold tabular-nums text-zinc-400">
                  <%= step.position %>
                </span>
                <div class="min-w-0">
                  <div class="truncate font-medium text-zinc-100"><%= step.name %></div>
                  <%= if step.people do %>
                    <div class="text-[10px] tabular-nums text-zinc-400"><%= step.people %> ppl</div>
                  <% end %>
                  <%= for line <- spec_lines(step.specs) do %>
                    <div class="text-[10px] text-zinc-400"><%= line %></div>
                  <% end %>
                </div>
                <span class="pt-0.5 text-right tabular-nums text-zinc-500">
                  <%= if step.estimated_minutes, do: "#{step.estimated_minutes}", else: "" %>
                </span>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp spec_lines(nil), do: []
  defp spec_lines(""), do: []

  defp spec_lines(specs) when is_binary(specs) do
    specs
    |> String.split(~r/\r?\n/)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp queue_card(assigns) do
    role_label =
      case assigns.node.queue_role do
        :storage_lot -> "Storage lot"
        :feeding_buffer -> "Feeding buffer"
        _ -> "Queue"
      end

    factory = assigns[:factory]
    menu_open? = assigns[:card_menu_id] == "n-#{assigns.node.id}"

    pencil_href =
      if factory do
        ~p"/factory/projects/#{factory.id}/nodes/#{assigns.node.id}/pencil?seq=#{assigns.sequence || assigns.node.position}"
      else
        "#"
      end

    assigns =
      assigns
      |> assign(:role_label, role_label)
      |> assign(:menu_open?, menu_open?)
      |> assign(:pencil_href, pencil_href)

    ~H"""
    <div class="w-full sm:w-[18rem] md:w-[18.5rem]">
      <div class="flex flex-col overflow-hidden rounded-none border border-zinc-200 bg-white text-xs dark:border-zinc-600 dark:bg-zinc-800">
        <div class="relative flex items-center gap-2 border-b border-sky-300 bg-sky-100 px-2.5 py-1.5 dark:border-sky-700 dark:bg-sky-900/30">
          <span class="inline-flex size-5 shrink-0 items-center justify-center rounded-full border border-sky-400 text-[10px] font-bold tabular-nums text-sky-800 dark:border-sky-500 dark:text-sky-200">
            <%= @sequence || @node.position %>
          </span>
          <h4 class="min-w-0 flex-1 truncate text-[10px] font-semibold uppercase tracking-wide text-zinc-900 dark:text-zinc-100">
            <%= @node.name %>
          </h4>
          <div class="relative shrink-0">
            <button
              type="button"
              phx-click="toggle_card_menu"
              phx-value-id={"n-#{@node.id}"}
              class="inline-flex h-5 w-5 items-center justify-center rounded text-sky-700 hover:bg-sky-200 hover:text-sky-950 dark:text-sky-200 dark:hover:bg-sky-800"
              title="Card menu"
              aria-label="Card menu"
              aria-expanded={to_string(@menu_open?)}
            >
              <span class="text-[14px] leading-none tracking-tighter" aria-hidden="true">⋮</span>
            </button>
            <%= if @menu_open? do %>
              <div
                class="absolute right-0 z-30 mt-1 w-44 overflow-hidden rounded border border-zinc-200 bg-white py-1 shadow-lg dark:border-zinc-600 dark:bg-zinc-800"
                role="menu"
              >
<a
                  href={@pencil_href}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="block px-3 py-1.5 text-left text-[11px] font-medium text-zinc-800 hover:bg-zinc-100 dark:text-zinc-100 dark:hover:bg-zinc-700"
                  role="menuitem"
                  data-phx-link="false"
                >
                  Print pencil sheet
                </a>
              </div>
            <% end %>
          </div>
        </div>
        <div class="space-y-1 px-2.5 py-1.5 text-[11px] text-zinc-600 dark:text-zinc-300">
          <div class="tabular-nums">
            <%= @role_label %>
            <%= if @node.slots do %>
              · <%= @node.slots %> slots
            <% end %>
            <%= if @node.bypass_allowed do %>
              · bypass
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
          <button type="button" phx-click="delete_node" phx-value-id={@node.id} data-confirm={"Remove #{@node.name}? This cannot be undone."} class="text-zinc-400 hover:text-red-500" title="Remove">×</button>
        </div>
      </div>
    </div>
    """
  end

defp work_cell_card(assigns) do
    steps = assigns.node.steps
    step_stats = Enum.map(steps, &StationMath.step_stat/1)

    content_total =
      step_stats
      |> Enum.map(& &1.content)
      |> Enum.reject(&is_nil/1)
      |> Enum.sum()
      |> case do
        0 -> 0
        n -> n
      end

    # Build parallel groups: linked steps share one time bucket (max stream) and sum people
    {ea_parallel, ea_phased, crew_designed, peak_phase} =
      StationMath.step_timing_summary(steps, step_stats)

    # Face chrome: vertical rail joins contiguous steps in the same parallel set (3–4, or 2–3–4).
    step_stats = annotate_parallel_rails(steps, step_stats)

    all_items =
      steps
      |> Enum.flat_map(fn s -> Map.get(s, :items) || [] end)

    stand_up_cents =
      all_items
      |> Enum.map(&FlowspecOps.Factories.FactoryNodeStepItem.stand_up_cents/1)
      |> Enum.reject(&is_nil/1)
      |> case do
        [] -> nil
        list -> Enum.sum(list)
      end

    burn_unit_cents =
      all_items
      |> Enum.map(&FlowspecOps.Factories.FactoryNodeStepItem.burn_per_unit_cents/1)
      |> Enum.reject(&is_nil/1)
      |> case do
        [] -> nil
        list -> Enum.sum(list)
      end

    slots = assigns.node.slots

    burn_batch_cents =
      cond do
        is_integer(burn_unit_cents) and is_integer(slots) and slots > 0 ->
          burn_unit_cents * slots

        true ->
          nil
      end

links = assigns[:links] || []
    factory = assigns[:factory]
    expected_in = expected_weekly_in(assigns.node, links)
    mpl = Enum.find(assigns.factory.master_production_lines, &(&1.id == assigns.node.line && assigns.node.line.master_production_line_id))
    need_wk = mpl && StationMath.required_weekly_rate(mpl)
    avail_label = inbound_avail_label(assigns.node, links)
    crew = crew_designed
    gate? = Map.get(assigns.node, :gate) == true
    menu_open? = assigns[:card_menu_id] == "n-#{assigns.node.id}"

    gap =
      if is_number(expected_in) and is_float(need_wk) do
        Float.round(need_wk - expected_in * 1.0, 1)
      else
        nil
      end

    # Series bay default: process batch = slots; batch cycle = slots × Ea (one unit method).
    batch_cycle_min =
      cond do
        is_integer(slots) and slots > 0 and is_integer(ea_parallel) and ea_parallel > 0 ->
          slots * ea_parallel

        true ->
          nil
      end

    # Throughput from one-unit cycle vs standard productive day (see node_design_spec §20).
    {rate_d, rate_w, rate_m} =
      StationMath.station_dwm_rates(if(ea_parallel > 0, do: ea_parallel, else: nil))

    rate_gap =
      if is_float(need_wk) and is_float(rate_w) do
        Float.round(need_wk - rate_w, 1)
      else
        nil
      end

    rate_gap_short? = is_float(rate_gap) and rate_gap > 0
    intake_short? = is_float(gap) and gap > 0

    status_circle =
      work_cell_status_circle(steps, content_total, ea_parallel, rate_gap_short? or intake_short?)

    assigns =
      assigns
      |> assign(:step_stats, step_stats)
      |> assign(:content_total, content_total)
      |> assign(:ea_parallel, ea_parallel)
      |> assign(:ea_phased, ea_phased)
      |> assign(:expected_in, expected_in)
      |> assign(:need_wk, need_wk)
      |> assign(:avail_label, avail_label)
      |> assign(:peak_people, crew_designed)
      |> assign(:peak_phase, peak_phase)
      |> assign(:stand_up_cents, stand_up_cents)
      |> assign(:burn_unit_cents, burn_unit_cents)
      |> assign(:burn_batch_cents, burn_batch_cents)
      |> assign(:crew, crew)
      |> assign(:gate?, gate?)
      |> assign(:status_circle, status_circle)
      |> assign(:intake_gap, gap)
      |> assign(:intake_short?, intake_short?)
      |> assign(:ea_label, format_duration_minutes(ea_parallel))
      |> assign(:ea_phased_label, format_duration_minutes(ea_phased))
      |> assign(:batch_cycle_min, batch_cycle_min)
      |> assign(:batch_cycle_label, format_duration_minutes(batch_cycle_min))
      |> assign(:rate_d, rate_d)
      |> assign(:rate_w, rate_w)
      |> assign(:rate_m, rate_m)
      |> assign(:rate_gap, rate_gap)
      |> assign(:rate_gap_short?, rate_gap_short?)
      |> assign(:menu_open?, menu_open?)
      |> assign(:standup_label, standup_face_label(assigns.node))
      |> assign(
        :pencil_href,
        ~p"/factory/projects/#{factory.id}/nodes/#{assigns.node.id}/pencil?seq=#{assigns.sequence || assigns.node.position}"
      )

    ~H"""
    <div class="w-full sm:w-[18rem] md:w-[18.5rem]">
      <div class="flex flex-col overflow-hidden rounded-none border border-zinc-200 bg-white text-xs dark:border-zinc-600 dark:bg-zinc-800">
        <div class="relative flex items-center gap-2 border-b border-zinc-300 bg-zinc-100 px-2.5 py-1.5 dark:border-zinc-500 dark:bg-zinc-700">
          <span class="inline-flex size-5 shrink-0 items-center justify-center rounded-full border border-zinc-400 text-[10px] font-bold tabular-nums text-zinc-900 dark:border-zinc-400 dark:text-zinc-100">
            <%= @sequence || @node.position %>
          </span>
          <button
            type="button"
            phx-click="open_station_edit"
            phx-value-id={@node.id}
            class="min-w-0 flex-1 truncate text-left text-[10px] font-semibold uppercase tracking-wide text-zinc-900 hover:text-indigo-600 dark:text-zinc-100 dark:hover:text-indigo-300"
            title="Edit station"
          >
            <%= @node.name %>
          </button>
          <%= if @node.slots do %>
            <span
              class="shrink-0 rounded border border-zinc-300 bg-white px-1 py-0.5 text-[9px] font-semibold tabular-nums text-zinc-600 dark:border-zinc-500 dark:bg-zinc-800 dark:text-zinc-200"
              title="Bay slots (process batch default)"
            >
              <%= @node.slots %> slots
            </span>
          <% end %>
          <div class="ml-auto flex shrink-0 items-center gap-1">
            <span
              class={[
                "rounded px-1 py-0.5 text-[9px] font-bold uppercase tracking-wide",
                @node.product_ready == true && "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300",
                @node.product_ready != true && "bg-zinc-200/80 text-zinc-500 dark:bg-zinc-700 dark:text-zinc-400"
              ]}
              title={if(@node.product_ready == true, do: "Product ready", else: "Product not ready — drawings/definition open")}
            >
              P
            </span>
            <span
              class={[
                "rounded px-1 py-0.5 text-[9px] font-bold uppercase tracking-wide",
                @node.method_instruction == true && "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300",
                @node.method_instruction != true && "bg-zinc-200/80 text-zinc-500 dark:bg-zinc-700 dark:text-zinc-400"
              ]}
              title={if(@node.method_instruction == true, do: "Method instruction in place", else: "Method instruction not confirmed")}
            >
              M
            </span>
            <button
              type="button"
              phx-click="toggle_gate"
              phx-value-id={@node.id}
              class={[
                "inline-flex h-5 min-w-[1.25rem] items-center justify-center rounded px-1 text-[10px] font-bold tracking-wide transition-colors",
                @gate? &&
                  "bg-amber-400 text-amber-950 ring-1 ring-amber-500 dark:bg-amber-500 dark:text-amber-950",
                !@gate? &&
                  "text-zinc-300 hover:text-amber-600 dark:text-zinc-600 dark:hover:text-amber-400"
              ]}
              title={if @gate?, do: "Gate on — click to clear", else: "Mark gate [G]"}
              aria-label={if @gate?, do: "Clear gate mark", else: "Set gate mark"}
              aria-pressed={to_string(@gate?)}
            >
              G
            </button>
            <span
              class={[
                "inline-flex size-2.5 shrink-0 rounded-full ring-1",
                @status_circle == :white && "bg-white ring-zinc-400 dark:bg-zinc-100 dark:ring-zinc-500",
                @status_circle == :orange && "bg-orange-500 ring-orange-600",
                @status_circle == :green && "bg-emerald-500 ring-emerald-600"
              ]}
              title={status_circle_title(@status_circle)}
              aria-label={status_circle_title(@status_circle)}
            >
            </span>
            <div class="relative">
              <button
                type="button"
                phx-click="toggle_card_menu"
                phx-value-id={"n-#{@node.id}"}
                class="inline-flex h-5 w-5 items-center justify-center rounded text-zinc-500 hover:bg-zinc-200 hover:text-zinc-800 dark:text-zinc-300 dark:hover:bg-zinc-600 dark:hover:text-zinc-50"
                title="Card menu"
                aria-label="Card menu"
                aria-expanded={to_string(@menu_open?)}
              >
                <span class="text-[14px] leading-none tracking-tighter" aria-hidden="true">⋮</span>
              </button>
              <%= if @menu_open? do %>
                <div
                  class="absolute right-0 z-30 mt-1 w-44 overflow-hidden rounded border border-zinc-200 bg-white py-1 shadow-lg dark:border-zinc-600 dark:bg-zinc-800"
                  role="menu"
                >
<a
                    href={@pencil_href}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="block px-3 py-1.5 text-left text-[11px] font-medium text-zinc-800 hover:bg-zinc-100 dark:text-zinc-100 dark:hover:bg-zinc-700"
                    role="menuitem"
                    data-phx-link="false"
                  >
                    Print pencil sheet
                  </a>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <%= if @expected_in do %>
          <div
            class="grid grid-cols-[minmax(0,1fr)_auto] gap-x-2 gap-y-0.5 border-b border-zinc-100 px-2.5 py-1.5 text-[11px] dark:border-zinc-700"
            title="Avail = linked transport deliveries into this door (planned). Need = factory promise rate. Gap = Need − Avail."
          >
            <span class="text-zinc-500 dark:text-zinc-400">Avail</span>
            <span class="tabular-nums text-right font-medium text-zinc-800 dark:text-zinc-100">
              <%= @avail_label || "—" %>
            </span>
            <span class="text-zinc-500 dark:text-zinc-400">Need</span>
            <span class="tabular-nums text-right"><%= if @need_wk, do: "#{format_rate(@need_wk)}/wk", else: "—" %></span>
            <span class="text-zinc-500 dark:text-zinc-400">Gap</span>
            <span class={[
              "tabular-nums text-right",
              @intake_short? && "text-amber-600 dark:text-amber-400",
              !@intake_short? && @intake_gap && "text-emerald-700 dark:text-emerald-300 font-semibold",
              is_nil(@intake_gap) && "font-semibold text-zinc-800 dark:text-zinc-100"
            ]}>
              <%= cond do %>
                <% is_nil(@intake_gap) -> %>
                  —
                <% @intake_short? -> %>
                  <%= format_rate(@intake_gap) %>
                <% @intake_gap < 0 -> %>
                  +<%= format_rate(abs(@intake_gap)) %>
                <% true -> %>
                  ok
              <% end %>
            </span>
          </div>
        <% end %>

        <div class="py-0.5">
          <%= for stat <- @step_stats do %>
            <% step = stat.step %>
            <button
              type="button"
              phx-click="open_step_edit"
              phx-value-id={step.id}
              class={[
                "group/row grid w-full grid-cols-[1.5rem_minmax(0,1fr)_auto] items-stretch gap-1.5 px-2.5 py-0 text-left text-xs hover:bg-zinc-50 dark:hover:bg-zinc-700/30",
                stat.parallel? && "bg-indigo-50/40 dark:bg-indigo-950/20"
              ]}
              title={if(stat.parallel?, do: "Parallel with linked step(s) — process time uses max in group", else: nil)}
            >
              <div class="flex flex-col items-center self-stretch">
                <div class={[
                  "w-0.5 flex-1 min-h-[0.35rem]",
                  stat.rail_up && "bg-indigo-400 dark:bg-indigo-500",
                  !stat.rail_up && "bg-transparent"
                ]}></div>
                <span class={[
                  "inline-flex size-5 shrink-0 items-center justify-center rounded-full border text-[10px] font-bold tabular-nums",
                  stat.parallel? &&
                    "border-indigo-500 text-indigo-700 dark:border-indigo-400 dark:text-indigo-200",
                  !stat.parallel? &&
                    "border-zinc-300 text-zinc-400 dark:border-zinc-500 dark:text-zinc-300"
                ]}>
                  <%= step.position %>
                </span>
                <div class={[
                  "w-0.5 flex-1 min-h-[0.35rem]",
                  stat.rail_down && "bg-indigo-400 dark:bg-indigo-500",
                  !stat.rail_down && "bg-transparent"
                ]}></div>
              </div>
              <div class="min-w-0 py-1.5">
                <div class="flex min-w-0 items-center gap-1">
                  <div class="truncate font-medium text-zinc-700 dark:text-zinc-200"><%= step.name %></div>
                  <%= if stat.parallel? do %>
                    <span class="shrink-0 text-[9px] font-bold uppercase tracking-wide text-indigo-600 dark:text-indigo-300" title="Runs in parallel">∥</span>
                  <% end %>
                </div>
                <div class="text-[10px] tabular-nums text-zinc-400">
                  <%= if stat.qty && stat.each do %>
                    ×<%= stat.qty %> · <%= stat.each %>m ea
                  <% else %>
                    —
                  <% end %>
                  <%= if stat.people do %>
                    · <%= stat.people %> ppl
                  <% end %>
                </div>
                <%= for item <- Map.get(step, :items) || [] do %>
                  <div class="text-[10px] text-zinc-400">
                    <%= if item.kind == :material do %>
                      material <%= item.name %><%= if item.qty, do: " · #{format_qty_input(item.qty)}/unit", else: "" %><%= if burn = FlowspecOps.Factories.FactoryNodeStepItem.burn_per_unit_cents(item) do %> · <%= format_money_cents(burn) %>/u<% end %>
                    <% else %>
                      machine <%= item.name %><%= if item.qty && item.qty != 1, do: " ×#{item.qty}", else: "" %><%= if item.unit_cost_cents, do: " #{format_money_cents(item.unit_cost_cents)}", else: "" %>
                    <% end %>
                  </div>
                <% end %>
              </div>
              <div class="py-1.5 text-right tabular-nums text-zinc-500 dark:text-zinc-300">
                <div><%= if stat.content, do: "#{stat.content}m", else: "—" %></div>
                <%= if stat.stream && stat.people && stat.people > 1 && stat.stream != stat.content do %>
                  <div class="text-[10px] text-zinc-400">→<%= stat.stream %>m</div>
                <% end %>
              </div>
            </button>
          <% end %>

          <%= if @add_step_node_id == @node.id do %>
            <form phx-submit="add_step" class="flex items-center gap-2 border-t border-dashed border-zinc-200 px-2.5 py-1.5 dark:border-zinc-600">
              <input type="hidden" name="node_id" value={@node.id} />
              <input
                type="text"
                name="name"
                placeholder="Step"
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
            + step
          </button>
        <% end %>

                <div class="border-t border-zinc-200 bg-zinc-50 px-2.5 py-2 dark:border-zinc-600 dark:bg-zinc-700/80">
          <%!-- Timing formula: CYCLE × BATCH = BATCH CYCLE (series bay default) --%>
          <div class="mb-2 flex items-end gap-1.5 tabular-nums text-zinc-700 dark:text-zinc-100">
            <div class="min-w-0 flex-1" title="One unit through this station (parallel steps = max process time)">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-zinc-400">Cycle</div>
              <div class="text-sm font-semibold"><%= @ea_label %></div>
            </div>
            <div class="pb-0.5 text-sm font-medium text-zinc-500" aria-hidden="true">×</div>
            <div class="min-w-0 flex-1" title="Process batch — defaults to bay slots">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-zinc-400">Batch</div>
              <div class="text-sm font-semibold"><%= @node.slots || "—" %></div>
            </div>
            <div class="min-w-0 flex-[1.35] text-right" title="Series bay: cycle × batch. Time to work a full process batch unit after unit.">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-zinc-400">Batch cycle</div>
              <div class="text-sm font-semibold"><%= @batch_cycle_label %></div>
            </div>
          </div>

          <div class="relative mb-2 grid grid-cols-5 gap-x-2 border-t border-zinc-200/80 pt-2 tabular-nums text-zinc-700 dark:border-zinc-600 dark:text-zinc-100">
            <div class="min-w-0" title="Units/day at cycle with standard productive day (360m)">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-zinc-400">D</div>
              <div class="text-sm font-semibold"><%= format_dwm(@rate_d) %></div>
            </div>
            <div class="min-w-0" title="Units/week = D × 5">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-zinc-400">W</div>
              <div class="text-sm font-semibold"><%= format_dwm(@rate_w) %></div>
            </div>
            <div class="relative min-w-0" title="Units/month = D × 20">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-zinc-400">M</div>
              <div class="text-sm font-semibold"><%= format_dwm(@rate_m) %></div>
              <span class="pointer-events-none absolute -right-1 top-1/2 -translate-y-1/2 text-[10px] font-medium text-zinc-400" aria-hidden="true">::</span>
            </div>
            <div class="min-w-0" title="Factory promise need (units/week)">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-zinc-400">N/wk</div>
              <div class="text-sm font-semibold">
                <%= if @need_wk, do: format_rate(@need_wk), else: "—" %>
              </div>
            </div>
            <div class="min-w-0" title="Gap = Need/wk − station W">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-zinc-400">G</div>
              <div class={[
                "text-sm",
                @rate_gap_short? && "font-normal text-amber-600 dark:text-amber-400",
                !@rate_gap_short? && @rate_gap && "font-semibold text-emerald-700 dark:text-emerald-300",
                is_nil(@rate_gap) && "font-semibold text-zinc-800 dark:text-zinc-100"
              ]}>
                <%= cond do %>
                  <% is_nil(@rate_gap) -> %>
                    —
                  <% @rate_gap_short? -> %>
                    <%= format_rate(@rate_gap) %>
                  <% @rate_gap < 0 -> %>
                    +<%= format_rate(abs(@rate_gap)) %>
                  <% true -> %>
                    ok
                <% end %>
              </div>
            </div>
          </div>

          <div class="relative grid grid-cols-4 gap-x-2 border-t border-zinc-200/80 pt-2 text-[11px] tabular-nums text-zinc-700 dark:border-zinc-600 dark:text-zinc-100">
            <div class="min-w-0" title="Designed people = sum of phase crews (∥ steps add inside a phase)">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-zinc-400">Crew</div>
              <div class="font-semibold">
                <%= @peak_people || "—" %><%= if @peak_people, do: " ppl", else: "" %>
              </div>
            </div>

            <div class="min-w-0" title="Machine asset $ (one-time kit total)">
              <div class="text-[9px] font-semibold uppercase tracking-wide text-zinc-400">Mach $</div>
              <div class="font-semibold">
                <%= if @stand_up_cents, do: format_money_cents(@stand_up_cents), else: "—" %>
              </div>
            </div>

            <div class="min-w-0" title="Materials / consumables per unit">
              <div class="truncate text-[9px] font-semibold uppercase tracking-wide text-zinc-400">Mat/u</div>
              <div class="font-semibold">
                <%= if @burn_unit_cents, do: format_money_cents(@burn_unit_cents), else: "—" %>
              </div>
            </div>

            <div class="min-w-0" title="Materials per process batch (mat/u × batch)">
              <div class="truncate text-[9px] font-semibold uppercase tracking-wide text-zinc-400">Mat/b</div>
              <div class="font-semibold">
                <%= if @burn_batch_cents, do: format_money_cents(@burn_batch_cents), else: "—" %>
              </div>
            </div>

            <button
              type="button"
              phx-click="delete_node"
              phx-value-id={@node.id}
              data-confirm={"Remove #{@node.name}? This cannot be undone."}
              class="absolute bottom-0 right-0 text-zinc-400 hover:text-red-500"
              title="Remove station"
            >
              ×
            </button>
          </div>

          <%= if @standup_label do %>
            <div
              class="mt-1.5 border-t border-zinc-200/80 pt-1.5 text-[10px] tabular-nums text-zinc-600 dark:border-zinc-600 dark:text-zinc-300"
              title="Stand-up demand to bring station online (full kit eng — not PM)"
            >
              <span class="font-semibold uppercase tracking-wide text-zinc-400">Stand-up</span>
              <span class="ml-1 font-medium text-zinc-800 dark:text-zinc-100"><%= @standup_label %></span>
            </div>
          <% end %>
        </div>

      </div>
    </div>
    """
  end


# Annotate step_stats with parallel face chrome: contiguous members of the same
  # parallel set get a vertical rail between badges (InDesign-style link, CSS).
  defp annotate_parallel_rails(steps, step_stats) do
    parent = StationMath.parallel_parent_map(steps)

    root_of = fn step -> StationMath.find_root(parent, step.id) end

    group_sizes =
      steps
      |> Enum.group_by(root_of)
      |> Map.new(fn {root, members} -> {root, length(members)} end)

    stats = Enum.with_index(step_stats)

    Enum.map(stats, fn {stat, idx} ->
      step = stat.step
      root = root_of.(step)
      parallel? = Map.get(group_sizes, root, 1) > 1

      prev = if idx > 0, do: Enum.at(step_stats, idx - 1)
      next = Enum.at(step_stats, idx + 1)

      rail_up =
        parallel? and prev != nil and root_of.(prev.step) == root

      rail_down =
        parallel? and next != nil and root_of.(next.step) == root

      stat
      |> Map.put(:parallel?, parallel?)
      |> Map.put(:rail_up, rail_up)
      |> Map.put(:rail_down, rail_down)
    end)
  end

# White = not enough data. Orange = short vs promise (rate G or intake gap).
  # Green reserved until fuller andon rules (do not fake green).
  defp work_cell_status_circle(steps, _content_total, ea_parallel, short?) do
    cond do
      steps == [] -> :white
      not (is_integer(ea_parallel) and ea_parallel > 0) -> :white
      short? -> :orange
      true -> :white
    end
  end

  defp status_circle_title(:white), do: "Need data"
  defp status_circle_title(:orange), do: "Short"
  defp status_circle_title(:green), do: "No blocks"
  defp status_circle_title(_), do: "Need data"

defp format_dwm(v), do: StationMath.format_dwm(v)

  defp format_duration_minutes(m), do: StationMath.format_duration_minutes(m)

  defp parse_money_to_cents(nil), do: nil
  defp parse_money_to_cents(""), do: nil

  defp parse_money_to_cents(s) when is_binary(s) do
    cleaned =
      s
      |> String.trim()
      |> String.replace("$", "")
      |> String.replace(",", "")

    cond do
      cleaned == "" ->
        nil

      String.contains?(cleaned, ".") ->
        case Float.parse(cleaned) do
          {f, _} -> round(f * 100)
          :error -> nil
        end

      true ->
        case Integer.parse(cleaned) do
          {i, _} -> i * 100
          :error -> nil
        end
    end
  end

  defp format_money_cents(nil), do: "—"

  defp format_money_cents(cents) when is_integer(cents) do
    dollars = div(cents, 100)
    rem_c = rem(abs(cents), 100)
    sign = if cents < 0, do: "-", else: ""

    if rem_c == 0 do
      "#{sign}$#{dollars}"
    else
      "#{sign}$#{dollars}.#{String.pad_leading(Integer.to_string(rem_c), 2, "0")}"
    end
  end

  defp format_money_input(cents) when is_integer(cents) do
    dollars = div(cents, 100)
    rem_c = rem(abs(cents), 100)

    if rem_c == 0 do
      Integer.to_string(dollars)
    else
      "#{dollars}.#{String.pad_leading(Integer.to_string(rem_c), 2, "0")}"
    end
  end

  defp items_total_cents(items) when is_list(items) do
    totals =
      items
      |> Enum.map(&FlowspecOps.Factories.FactoryNodeStepItem.line_total_cents/1)
      |> Enum.reject(&is_nil/1)

    case totals do
      [] -> nil
      list -> Enum.sum(list)
    end
  end

  defp checkbox_true?(params, key) do
    case Map.get(params, key) do
      v when v in [true, "true", "on", "1", 1] -> true
      _ -> false
    end
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(s) when is_binary(s) do
    case String.trim(s) do
      "" -> nil
      other -> other
    end
  end

  defp find_step(factory, step_id) do
    factory.nodes
    |> Enum.flat_map(fn n -> Enum.map(n.steps, &{n, &1}) end)
    |> Enum.find(fn {_n, s} -> s.id == step_id end)
  end

  defp step_edit_modal(assigns) do
    found = find_step(assigns.factory, assigns.step_edit_id)

    assigns =
      case found do
        {node, step} ->
          items = Map.get(step, :items) || []
          equip = Enum.filter(items, &(&1.kind == :equipment))
          mats = Enum.filter(items, &(&1.kind == :material))
          siblings = Enum.reject(node.steps, &(&1.id == step.id))

          qty = step.qty_per_unit
          each = step.minutes_each

          content =
            cond do
              is_integer(qty) and is_integer(each) -> qty * each
              is_integer(step.estimated_minutes) -> step.estimated_minutes
              true -> nil
            end

          process = FactoryNodeStep.process_minutes(step)

          assign(assigns,
            node: node,
            step: step,
            sibling_steps: siblings,
            equip_items: equip,
            material_items: mats,
            stand_up_total_cents: sum_cents(equip, :stand_up),
            burn_total_cents: sum_cents(mats, :burn),
            work_content_min: content,
            work_process_min: process
          )

        nil ->
          assign(assigns,
            node: nil,
            step: nil,
            sibling_steps: [],
            equip_items: [],
            material_items: [],
            stand_up_total_cents: nil,
            burn_total_cents: nil,
            work_content_min: nil,
            work_process_min: nil
          )
      end

    ~H"""
    <%= if @step do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-zinc-900/40" phx-click="cancel_step_edit"></div>
        <div class="relative max-h-[90vh] w-full max-w-xl overflow-y-auto rounded-lg border border-zinc-200 bg-white p-4 shadow-xl dark:border-zinc-700 dark:bg-zinc-900">
          <h3 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">Step · <%= @node.name %></h3>

          <form id={"save-step-#{@step.id}"} phx-change="save_step" phx-submit="save_step" class="mt-3 space-y-3">
            <input type="hidden" name="step_id" value={@step.id} />

            <label class="block">
              <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Step name</span>
              <input
                type="text"
                name="name"
                value={@step.name}
                form={"save-step-#{@step.id}"}
                class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
              />
            </label>

            <div
              id={"step-cycle-#{@step.id}"}
              phx-hook="StepCycleCalc"
              class="flex flex-wrap items-end gap-x-2 gap-y-2"
            >
              <label class="block w-[4.75rem]">
                <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Qty / unit</span>
                <input
                  type="number"
                  name="qty_per_unit"
                  min="1"
                  value={@step.qty_per_unit}
                  data-cycle-qty
                  form={"save-step-#{@step.id}"}
                  class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
                />
              </label>

              <span class="pb-2 text-sm font-medium text-zinc-500">×</span>

              <label class="block w-[4.75rem]">
                <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Min / ea</span>
                <input
                  type="number"
                  name="minutes_each"
                  min="1"
                  value={@step.minutes_each}
                  data-cycle-each
                  form={"save-step-#{@step.id}"}
                  class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
                />
              </label>

              <div class="w-[3.5rem] pb-2 text-center">
                <div class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Cycle</div>
                <div
                  data-cycle-out
                  class="mt-1 text-sm font-semibold tabular-nums text-zinc-800 dark:text-zinc-100"
                >
                  <%= if @work_content_min, do: "#{@work_content_min}m", else: "—" %>
                </div>
              </div>

              <label class="block w-[4.25rem]">
                <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">People</span>
                <input
                  type="number"
                  name="people"
                  min="1"
                  value={@step.people}
                  data-cycle-people
                  form={"save-step-#{@step.id}"}
                  class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
                />
              </label>

              <div class="pb-2">
                <div class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Process time</div>
                <div class="mt-1 flex items-center gap-1.5">
                  <span class="text-sm font-medium text-zinc-500">=</span>
                  <div
                    data-process-out
                    class="min-w-[2.5rem] text-sm font-semibold tabular-nums text-zinc-800 dark:text-zinc-100"
                  >
                    <%= if @work_process_min, do: "#{@work_process_min}m", else: "—" %>
                  </div>
                </div>
              </div>

              <label class="inline-flex items-center gap-1.5 pb-2 text-[11px] font-medium text-zinc-600 dark:text-zinc-300">
                <input
                  type="checkbox"
                  name="shared"
                  value="true"
                  checked={@step.shared != false}
                  data-cycle-shared
                  form={"save-step-#{@step.id}"}
                  class="rounded border-zinc-400"
                />
                Shared
              </label>
            </div>

            <div class="mt-3 flex flex-wrap items-center gap-2">
              <label class="inline-flex items-center gap-2 text-[11px] font-medium text-zinc-700 dark:text-zinc-200">
                <input
                  type="checkbox"
                  name="parallel_enabled"
                  form={"save-step-#{@step.id}"}
                  value="true"
                  checked={!!@step.parallel_with_step_id}
                  class="rounded border-zinc-400"
                />
                Parallel with
              </label>
              <select
                name="parallel_with_step_id"
                form={"save-step-#{@step.id}"}
                class="min-w-[10rem] rounded border border-zinc-300 bg-white px-2 py-1 text-[11px] dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
              >
                <option value="none">—</option>
                <%= for s <- @sibling_steps do %>
                  <option value={s.id} selected={@step.parallel_with_step_id == s.id}>
                    <%= s.position %>. <%= s.name %>
                  </option>
                <% end %>
              </select>
            </div>
          </form>

          <div class="mt-4 border-t border-zinc-200 pt-3 dark:border-zinc-700">
            <h4 class="text-[10px] font-semibold uppercase tracking-wide text-zinc-500">Machines</h4>
            <p class="mb-1.5 text-[10px] text-zinc-400">Assets at the station (saw, table, power…)</p>
            <.item_section
              items={@equip_items}
              mode={:stand_up}
              step_id={@step.id}
              total_cents={@stand_up_total_cents}
            />
          </div>

          <div class="mt-4 border-t border-zinc-200 pt-3 dark:border-zinc-700">
            <h4 class="text-[10px] font-semibold uppercase tracking-wide text-zinc-500">Materials</h4>
            <p class="mb-1.5 text-[10px] text-zinc-400">Consumables burned per unit</p>
            <.item_section
              items={@material_items}
              mode={:burn}
              step_id={@step.id}
              total_cents={@burn_total_cents}
            />
          </div>

          <div class="mt-4 flex items-center justify-end gap-2 border-t border-zinc-100 pt-3 dark:border-zinc-800">
            <button
              type="button"
              phx-click="delete_step"
              phx-value-id={@step.id}
              data-confirm={"Remove step \\"#{@step.name}\\"? This cannot be undone."}
              class="mr-auto text-xs text-red-600 hover:text-red-500"
            >
              Delete step
            </button>
            <button
              type="button"
              phx-click="cancel_step_edit"
              class="rounded px-3 py-1.5 text-xs font-medium text-zinc-600 hover:bg-zinc-100 dark:text-zinc-300 dark:hover:bg-zinc-800"
            >
              Close
            </button>
            <button
              type="submit"
              form={"save-step-#{@step.id}"}
              class="rounded bg-zinc-900 px-3 py-1.5 text-xs font-semibold text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900"
            >
              Save
            </button>
          </div>

        </div>
      </div>
    <% end %>
    """
  end

  # One section = table + add row inside table + total under both
  defp item_section(assigns) do
    ~H"""
    <div id={"item-section-#{@mode}-#{@step_id}"} phx-hook="TabSubmitLast" class="overflow-hidden rounded border border-zinc-200 dark:border-zinc-600">
      <table class="w-full table-fixed text-left text-[11px]">
        <%= if @mode == :burn do %>
          <colgroup>
            <col class="w-[40%]" />
            <col class="w-[12%]" />
            <col class="w-[12%]" />
            <col class="w-[14%]" />
            <col class="w-[14%]" />
            <col class="w-[8%]" />
          </colgroup>
        <% else %>
          <colgroup>
            <col class="w-[46%]" />
            <col class="w-[14%]" />
            <col class="w-[16%]" />
            <col class="w-[16%]" />
            <col class="w-[8%]" />
          </colgroup>
        <% end %>
        <thead class="bg-zinc-50 text-[10px] uppercase tracking-wide text-zinc-400 dark:bg-zinc-800 dark:text-zinc-500">
          <tr>
            <th class="px-2 py-1.5 font-semibold">Item</th>
            <%= if @mode == :burn do %>
              <th class="px-1 py-1.5 text-right font-semibold" title="Burn qty per station deliverable">/unit</th>
              <th class="px-1 py-1.5 text-right font-semibold" title="Pieces per pack/box">Pack</th>
              <th class="px-1 py-1.5 text-right font-semibold" title="Price per pack/box">Box $</th>
              <th class="px-1 py-1.5 text-right font-semibold">$/unit</th>
            <% else %>
              <th class="px-1 py-1.5 text-right font-semibold">Qty</th>
              <th class="px-1 py-1.5 text-right font-semibold">Unit $</th>
              <th class="px-1 py-1.5 text-right font-semibold">Line</th>
            <% end %>
            <th class="px-1 py-1.5"></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-zinc-100 dark:divide-zinc-700">
          <%= if @items == [] do %>
            <tr>
              <td colspan={if(@mode == :burn, do: 6, else: 5)} class="px-2 py-2 text-center text-zinc-400">
                <%= if @mode == :burn, do: "No materials yet", else: "No machines yet" %>
              </td>
            </tr>
          <% end %>

          <%= for item <- @items do %>
            <tr class="text-zinc-700 dark:text-zinc-200">
              <td class="px-1.5 py-1 align-middle">
                <form phx-change="update_step_item" phx-submit="update_step_item">
                  <input type="hidden" name="item_id" value={item.id} />
                  <input
                    type="text"
                    name="name"
                    value={item.name}
                    class="w-full rounded border border-transparent bg-transparent px-1 py-0.5 text-[11px] font-medium hover:border-zinc-300 focus:border-indigo-400 focus:bg-white focus:outline-none dark:focus:bg-zinc-800"
                  />
                </form>
              </td>

              <%= if @mode == :burn do %>
                <td class="px-1 py-1 align-middle">
                  <form phx-change="update_step_item" phx-submit="update_step_item">
                    <input type="hidden" name="item_id" value={item.id} />
                    <input type="number" name="qty" min="0" step="any" value={format_qty_input(item.qty)}
                      class="w-full rounded border border-transparent bg-transparent px-1 py-0.5 text-right text-[11px] tabular-nums hover:border-zinc-300 focus:border-indigo-400 focus:bg-white focus:outline-none dark:focus:bg-zinc-800" />
                  </form>
                </td>
                <td class="px-1 py-1 align-middle">
                  <form phx-change="update_step_item" phx-submit="update_step_item">
                    <input type="hidden" name="item_id" value={item.id} />
                    <input type="number" name="pack_qty" min="0" step="any" value={format_qty_input(item.pack_qty)} placeholder="—"
                      class="w-full rounded border border-transparent bg-transparent px-1 py-0.5 text-right text-[11px] tabular-nums hover:border-zinc-300 focus:border-indigo-400 focus:bg-white focus:outline-none dark:focus:bg-zinc-800" />
                  </form>
                </td>
                <td class="px-1 py-1 align-middle">
                  <form phx-change="update_step_item" phx-submit="update_step_item">
                    <input type="hidden" name="item_id" value={item.id} />
                    <input type="text" name="unit_cost"
                      value={if item.unit_cost_cents, do: format_money_input(item.unit_cost_cents), else: ""}
                      placeholder="—"
                      class="w-full rounded border border-transparent bg-transparent px-1 py-0.5 text-right text-[11px] tabular-nums hover:border-zinc-300 focus:border-indigo-400 focus:bg-white focus:outline-none dark:focus:bg-zinc-800" />
                  </form>
                </td>
                <td class="px-1 py-1 text-right align-middle tabular-nums font-medium">
                  <%= case FlowspecOps.Factories.FactoryNodeStepItem.burn_per_unit_cents(item) do %>
                    <% nil -> %>—
                    <% c -> %><%= format_money_cents(c) %>
                  <% end %>
                </td>
              <% else %>
                <td class="px-1 py-1 align-middle">
                  <form phx-change="update_step_item" phx-submit="update_step_item">
                    <input type="hidden" name="item_id" value={item.id} />
                    <input type="number" name="qty" min="0" step="any" value={format_qty_input(item.qty)}
                      class="w-full rounded border border-transparent bg-transparent px-1 py-0.5 text-right text-[11px] tabular-nums hover:border-zinc-300 focus:border-indigo-400 focus:bg-white focus:outline-none dark:focus:bg-zinc-800" />
                  </form>
                </td>
                <td class="px-1 py-1 align-middle">
                  <form phx-change="update_step_item" phx-submit="update_step_item">
                    <input type="hidden" name="item_id" value={item.id} />
                    <input type="text" name="unit_cost"
                      value={if item.unit_cost_cents, do: format_money_input(item.unit_cost_cents), else: ""}
                      placeholder="—"
                      class="w-full rounded border border-transparent bg-transparent px-1 py-0.5 text-right text-[11px] tabular-nums hover:border-zinc-300 focus:border-indigo-400 focus:bg-white focus:outline-none dark:focus:bg-zinc-800" />
                  </form>
                </td>
                <td class="px-1 py-1 text-right align-middle tabular-nums font-medium">
                  <%= case FlowspecOps.Factories.FactoryNodeStepItem.stand_up_cents(item) do %>
                    <% nil -> %>—
                    <% c -> %><%= format_money_cents(c) %>
                  <% end %>
                </td>
              <% end %>

              <td class="px-1 py-1 text-right align-middle">
                <button
                  type="button"
                  phx-click="delete_step_item"
                  phx-value-id={item.id}
                  data-confirm={"Remove #{item.name}?"}
                  class="text-zinc-300 hover:text-red-500"
                >
                  ×
                </button>
              </td>
            </tr>
          <% end %>

          <%!-- compact add row: inputs associated via form= (valid HTML) --%>
          <tr class="bg-zinc-50/80 dark:bg-zinc-800/40">
              <td class="px-1.5 py-1">
                <input
                  type="text"
                  name="name"
                  required
                  form={"add-item-#{@mode}-#{@step_id}"}
                  placeholder={if @mode == :burn, do: "Material", else: "Machine"}
                  class="w-full rounded border border-zinc-300 bg-white px-1.5 py-1 text-[11px] dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
                />
              </td>
              <%= if @mode == :burn do %>
                <td class="px-1 py-1">
                  <input type="number" name="qty" min="0" step="any" value="1" form={"add-item-#{@mode}-#{@step_id}"}
                    class="w-full rounded border border-zinc-300 bg-white px-1 py-1 text-right text-[11px] tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100" />
                </td>
                <td class="px-1 py-1">
                  <input type="number" name="pack_qty" min="0" step="any" placeholder="Pack" form={"add-item-#{@mode}-#{@step_id}"}
                    class="w-full rounded border border-zinc-300 bg-white px-1 py-1 text-right text-[11px] tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100" />
                </td>
                <td class="px-1 py-1">
                  <input type="text" name="unit_cost" placeholder="Box $" form={"add-item-#{@mode}-#{@step_id}"}
                    class="w-full rounded border border-zinc-300 bg-white px-1 py-1 text-right text-[11px] tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100" />
                </td>
                <td class="px-1 py-1 text-right text-zinc-400">—</td>
              <% else %>
                <td class="px-1 py-1">
                  <input type="number" name="qty" min="0" step="any" value="1" form={"add-item-#{@mode}-#{@step_id}"}
                    class="w-full rounded border border-zinc-300 bg-white px-1 py-1 text-right text-[11px] tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100" />
                </td>
                <td class="px-1 py-1">
                  <input type="text" name="unit_cost" placeholder="$" form={"add-item-#{@mode}-#{@step_id}"}
                    class="w-full rounded border border-zinc-300 bg-white px-1 py-1 text-right text-[11px] tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100" />
                </td>
                <td class="px-1 py-1 text-right text-zinc-400">—</td>
              <% end %>
              <td class="px-1 py-1 text-right">
                <button
                  type="submit"
                  form={"add-item-#{@mode}-#{@step_id}"}
                  class="rounded bg-zinc-800 px-1.5 py-1 text-[11px] font-semibold text-white hover:bg-zinc-700 dark:bg-zinc-200 dark:text-zinc-900"
                >
                  +
                </button>
              </td>
          </tr>
        </tbody>
      </table>
    </div>

    <form phx-submit="add_step_item" id={"add-item-#{@mode}-#{@step_id}"} class="hidden">
      <input type="hidden" name="step_id" value={@step_id} />
      <input type="hidden" name="kind" value={if(@mode == :burn, do: "material", else: "equipment")} />
    </form>

    <div class="mt-1.5 flex justify-end px-1 text-[11px] font-semibold tabular-nums text-zinc-800 dark:text-zinc-100">
      <%= if @mode == :burn do %>
        <span class="text-zinc-400 font-medium mr-2">Total / unit</span>
        <%= if @total_cents, do: format_money_cents(@total_cents), else: "—" %>
      <% else %>
        <span class="text-zinc-400 font-medium mr-2">Total</span>
        <%= if @total_cents, do: format_money_cents(@total_cents), else: "—" %>
      <% end %>
    </div>
    """
  end

  defp sum_cents(items, :stand_up) do
    items
    |> Enum.map(&FlowspecOps.Factories.FactoryNodeStepItem.stand_up_cents/1)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      list -> Enum.sum(list)
    end
  end

  defp sum_cents(items, :burn) do
    items
    |> Enum.map(&FlowspecOps.Factories.FactoryNodeStepItem.burn_per_unit_cents/1)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      list -> Enum.sum(list)
    end
  end

  defp transport_edit_modal(assigns) do
    node = Enum.find(assigns.factory.nodes, &(&1.id == assigns.transport_edit_id))
    assigns = assign(assigns, :node, node)

    ~H"""
    <%= if @node do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-zinc-900/40" phx-click="cancel_transport_edit"></div>
        <div class="relative w-full max-w-sm rounded-lg border border-zinc-200 bg-white p-4 shadow-xl dark:border-zinc-700 dark:bg-zinc-900">
          <h3 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">Transport · <%= @node.name %></h3>
          <p class="mt-0.5 text-[11px] text-zinc-500 dark:text-zinc-400">Route and schedule details.</p>

          <form phx-submit="save_transport" class="mt-3 space-y-3">
            <input type="hidden" name="node_id" value={@node.id} />

            <label class="block">
              <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Name</span>
              <input
                type="text"
                name="name"
                value={@node.name}
                class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
              />
            </label>

            <label class="block">
              <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Vendor / carrier</span>
              <input
                type="text"
                name="vendor_name"
                value={@node.vendor_name}
                class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
              />
            </label>

            <div class="flex gap-2">
              <label class="block flex-1">
                <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">From</span>
                <input
                  type="text"
                  name="from_location"
                  value={@node.from_location}
                  class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
                />
              </label>
              <label class="block flex-1">
                <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">To</span>
                <input
                  type="text"
                  name="to_location"
                  value={@node.to_location}
                  class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
                />
              </label>
            </div>

            <div class="flex gap-2">
              <label class="block flex-1">
                <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Batch size</span>
                <input
                  type="number"
                  name="batch_size"
                  min="1"
                  value={@node.batch_size}
                  class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
                />
              </label>
              <label class="block flex-1">
                <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Transit days</span>
                <input
                  type="number"
                  name="transit_days"
                  min="1"
                  value={@node.transit_days}
                  class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
                />
              </label>
            </div>

            <label class="block">
              <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Ship weekday</span>
              <input
                type="text"
                name="ship_weekday"
                value={@node.ship_weekday}
                placeholder="thursday"
                class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
              />
            </label>

            <label class="block">
              <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Note</span>
              <textarea
                name="note"
                rows="2"
                class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
              ><%= @node.note %></textarea>
            </label>

            <div class="flex items-center justify-end gap-2 pt-1">
              <button type="button" phx-click="cancel_transport_edit" class="px-2 py-1 text-xs text-zinc-500 hover:text-zinc-700 dark:text-zinc-400">
                Cancel
              </button>
              <button type="submit" class="rounded bg-zinc-900 px-3 py-1 text-xs font-semibold text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900">
                Save
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
    """
  end

  defp station_edit_modal(assigns) do
    node = Enum.find(assigns.factory.nodes, &(&1.id == assigns.station_edit_id))
    assigns = assign(assigns, node: node)

    ~H"""
    <%= if @node do %>
      <div class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-zinc-900/40" phx-click="cancel_station_edit"></div>
        <div class="relative w-full max-w-sm rounded-lg border border-zinc-200 bg-white p-4 shadow-xl dark:border-zinc-700 dark:bg-zinc-900">
          <h3 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">Station</h3>
          <p class="mt-0.5 text-[11px] text-zinc-500 dark:text-zinc-400">
            Name, design gates, bay slots, stand-up demand. Steps edited on each row. Gates print on PDF.
          </p>

          <form phx-submit="save_station" class="mt-3 space-y-3">
            <input type="hidden" name="node_id" value={@node.id} />

            <label class="block">
              <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Name</span>
              <input
                type="text"
                name="name"
                value={@node.name}
                class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
              />
            </label>

            <div class="space-y-2 rounded border border-zinc-200 bg-zinc-50 px-2.5 py-2 dark:border-zinc-600 dark:bg-zinc-800/40">
              <div class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">
                Design gates · PDF
              </div>
              <label class="flex items-start gap-2 text-[12px] text-zinc-800 dark:text-zinc-100">
                <input
                  type="checkbox"
                  name="product_ready"
                  value="true"
                  checked={@node.product_ready == true}
                  class="mt-0.5 rounded border-zinc-400"
                />
                <span>
                  <span class="font-medium">Product ready</span>
                  <span class="block text-[10px] text-zinc-500 dark:text-zinc-400">
                    Released drawings / product definition frozen enough to full-kit (not still moving holes).
                  </span>
                </span>
              </label>
              <label class="flex items-start gap-2 text-[12px] text-zinc-800 dark:text-zinc-100">
                <input
                  type="checkbox"
                  name="method_instruction"
                  value="true"
                  checked={@node.method_instruction == true}
                  class="mt-0.5 rounded border-zinc-400"
                />
                <span>
                  <span class="font-medium">Method instruction</span>
                  <span class="block text-[10px] text-zinc-500 dark:text-zinc-400">
                    Standard work / instruction exists and people can run the method.
                  </span>
                </span>
              </label>
            </div>

            <label class="block">
              <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Slots (bay)</span>
              <input
                type="number"
                name="slots"
                min="1"
                value={@node.slots}
                class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
              />
            </label>

            <div class="space-y-2 rounded border border-zinc-200 bg-zinc-50 px-2.5 py-2 dark:border-zinc-600 dark:bg-zinc-800/40">
              <div class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">
                Stand-up · online demand
              </div>
              <p class="text-[10px] text-zinc-500 dark:text-zinc-400">
                What it takes to bring this station online (if full kit). Engineered here — not managed here.
              </p>
              <div class="grid grid-cols-3 gap-2">
                <label class="block">
                  <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Weeks</span>
                  <input
                    type="number"
                    name="standup_weeks"
                    min="0"
                    step="any"
                    value={format_qty_input(@node.standup_weeks)}
                    placeholder="—"
                    class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
                  />
                </label>
                <label class="block">
                  <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">People</span>
                  <input
                    type="number"
                    name="standup_people"
                    min="1"
                    value={@node.standup_people}
                    placeholder="—"
                    class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm tabular-nums dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
                  />
                </label>
                <label class="block">
                  <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Source</span>
                  <select
                    name="standup_source"
                    class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
                  >
                    <option value="" selected={is_nil(@node.standup_source)}>—</option>
                    <option value="in_house" selected={@node.standup_source == :in_house}>In-house</option>
                    <option value="subcontract" selected={@node.standup_source == :subcontract}>Subcontract</option>
                    <option value="mixed" selected={@node.standup_source == :mixed}>Mixed</option>
                  </select>
                </label>
              </div>
              <label class="block">
                <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Stand-up note</span>
                <input
                  type="text"
                  name="standup_note"
                  value={@node.standup_note}
                  placeholder="Vendor, scope, dependencies…"
                  class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
                />
              </label>
            </div>

            <label class="block">
              <span class="text-[10px] font-semibold uppercase tracking-wide text-zinc-400">Note</span>
              <textarea
                name="note"
                rows="2"
                class="mt-1 w-full rounded border border-zinc-300 bg-white px-2 py-1.5 text-sm dark:border-zinc-600 dark:bg-zinc-800 dark:text-zinc-100"
              ><%= @node.note %></textarea>
            </label>

            <div class="flex items-center justify-end gap-2 pt-1">
              <button type="button" phx-click="cancel_station_edit" class="px-2 py-1 text-xs text-zinc-500 hover:text-zinc-700 dark:text-zinc-400">
                Cancel
              </button>
              <button type="submit" class="rounded bg-zinc-900 px-3 py-1 text-xs font-semibold text-white hover:bg-zinc-700 dark:bg-zinc-100 dark:text-zinc-900">
                Save
              </button>
            </div>
          </form>
        </div>
      </div>
    <% end %>
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
