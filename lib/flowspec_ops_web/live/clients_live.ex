defmodule FlowspecOpsWeb.ClientsLive do
  use FlowspecOpsWeb, :live_view
  import Ecto.Query, only: [from: 2]

  alias FlowspecOps.Repo
  alias FlowspecOps.Sales.{ActivityLogEntry, Task, TimeEntry}

  @wip_cap 2

  @impl true
  def mount(_params, _session, socket) do
    tasks = load_tasks()
    selected_task_id = tasks |> List.first() |> then(& &1 && &1.id)

    {:ok,
     assign(socket,
       tasks: tasks,
       selected_task_id: selected_task_id,
       selected_task_tab: "global",
       selected_tab: "work",
       notes_drawer_open: true,
       editing_time_entry_id: nil,
       log_drafts: %{},
       page_title: "Clients"
     )}
  end

  @impl true
  def handle_event("select_task", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_task_id: parse_id(id))}
  end

  @impl true
  def handle_event("select_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, selected_tab: tab)}
  end
  @impl true
  def handle_event("select_task_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, selected_task_tab: tab)}
  end

  @impl true
  def handle_event("toggle_notes_drawer", _params, socket) do
    {:noreply, update(socket, :notes_drawer_open, &(!&1))}
  end

  @impl true
  def handle_event("update_rank", params, socket) do
    id = params["id"]
    raw_rank = params["rank"] || params["value"]
    with {:ok, rank} <- parse_integer(raw_rank),
         task_id when not is_nil(task_id) <- parse_id(id) do
      reorder_priorities(rank, task_id)
    end

    {:noreply, reload_tasks(socket)}
  end

  @impl true
  def handle_event("update_task_field", %{"id" => id, "field" => field, "value" => value}, socket) do
    with task_id when not is_nil(task_id) <- parse_id(id),
         %Task{} = task <- find_task(socket.assigns.tasks, task_id),
         {:ok, updates} <- task_updates(task, field, value) do
      task
      |> Task.changeset(updates)
      |> Repo.update()
    end

    {:noreply, reload_tasks(socket)}
  end

  @impl true
  def handle_event("update_log_draft", %{"id" => id, "type" => type, "body" => body}, socket) do
    key = "#{id}:#{type}"
    {:noreply, update(socket, :log_drafts, &Map.put(&1, key, body))}
  end

  @impl true
  def handle_event("add_log_entry", %{"task_id" => id, "type" => type, "author" => author, "body" => body}, socket) do
    body = String.trim(body || "")

    if body == "" do
      {:noreply, socket}
    else
      task = find_task(socket.assigns.tasks, parse_id(id))

      if task do
        Repo.insert!(ActivityLogEntry.changeset(%ActivityLogEntry{}, %{
          client_id: task.client_id,
          contact_id: task.contact_id,
          kind: log_kind(type),
          author: author,
          body: body,
          occurred_at: DateTime.utc_now()
        }))
      end

      draft_key = "#{id}:#{type}"

      {:noreply,
       socket
       |> update(:log_drafts, &Map.put(&1, draft_key, ""))
       |> reload_tasks()}
    end
  end

  @impl true
  def handle_event("start_edit_time_entry", %{"id" => id}, socket) do
    {:noreply, assign(socket, editing_time_entry_id: parse_id(id))}
  end

  @impl true
  def handle_event("cancel_edit_time_entry", _params, socket) do
    {:noreply, assign(socket, editing_time_entry_id: nil)}
  end

  @impl true
  def handle_event("save_time_entry", params, socket) do
    entry_id = parse_id(params["entry_id"])
    duration = parse_integer(params["duration_minutes"])
    note = params["note"]
    billable = checkbox_value(params["billable"])

    with entry_id when not is_nil(entry_id) <- entry_id,
         {:ok, minutes} <- duration,
         true <- minutes > 0,
         %TimeEntry{} = entry <- Repo.get(TimeEntry, entry_id) do
      ended_at = entry.ended_at || DateTime.utc_now()
      started_at = DateTime.add(ended_at, -minutes * 60, :second)

      entry
      |> TimeEntry.changeset(%{started_at: started_at, ended_at: ended_at, note: note, billable: billable})
      |> Repo.update()
    else
      _ -> :noop
    end

    {:noreply,
     socket
     |> assign(editing_time_entry_id: nil)
     |> reload_tasks()}
  end

  @impl true
  def handle_event("add_time_entry", params, socket) do
    task_id = parse_id(params["task_id"])
    duration = parse_integer(params["duration_minutes"])
    note = params["note"]
    billable = checkbox_value(params["billable"])

    with task_id when not is_nil(task_id) <- task_id,
         {:ok, minutes} <- duration,
         true <- minutes > 0 do
      ended_at = DateTime.utc_now()
      started_at = DateTime.add(ended_at, -minutes * 60, :second)

      Repo.insert!(TimeEntry.changeset(%TimeEntry{}, %{
        task_id: task_id,
        started_at: started_at,
        ended_at: ended_at,
        note: note,
        billable: billable
      }))
    else
      _ -> :noop
    end

    {:noreply, reload_tasks(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex flex-wrap items-center justify-between gap-2">
        <div>
          <h1 class="text-xl font-semibold text-zinc-900 dark:text-zinc-100">Clients</h1>
          <p class="text-sm text-zinc-600 dark:text-zinc-300">
            Global priority work surface with inline edits and live logs.
          </p>
        </div>
        <% {active_count, cap} = wip_cap(@tasks) %>
        <div class="inline-flex items-center gap-2 rounded-full border border-amber-200 bg-amber-50 px-3 py-1 text-xs font-semibold text-amber-700 dark:border-amber-500/40 dark:bg-amber-500/10 dark:text-amber-200">
          WIP <span class="rounded-full bg-amber-200/70 px-2 py-0.5 text-[10px] font-bold text-amber-700 dark:bg-amber-500/40 dark:text-amber-100"><%= active_count %>/<%= cap %> active</span>
        </div>
      </div>

      <div class="flex items-center justify-end">
        <button
          type="button"
          phx-click="toggle_notes_drawer"
          class="rounded-md border border-zinc-200 bg-white px-2 py-1 text-xs font-medium text-zinc-700 hover:bg-zinc-100 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-200 dark:hover:bg-zinc-800"
        >
          <%= if @notes_drawer_open, do: "Hide notes", else: "Show notes" %>
        </button>
      </div>

      <div class="flex flex-col gap-3 xl:flex-row">
        <div class="flex-1 min-w-0 rounded-lg border border-zinc-200 bg-zinc-50 shadow-sm dark:border-zinc-800 dark:bg-zinc-950">
          <div class="px-4 pt-3">
            <div class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">Global task table</div>
            <div class="text-xs text-zinc-500 dark:text-zinc-400">Canonical priority order. Click a row to open logs.</div>
          </div>
          <div class="px-4 pt-3">
            <div class="flex items-end gap-2">
              <button
                type="button"
                phx-click="select_task_tab"
                phx-value-tab="global"
                class={[
                  "relative -mb-px rounded-t-md border px-4 py-2 text-xs font-semibold",
                  @selected_task_tab == "global" &&
                    "z-10 border-zinc-200 border-b-0 bg-white text-zinc-900 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-100",
                  @selected_task_tab != "global" &&
                    "mt-1 border-amber-200 bg-amber-100 text-amber-900 shadow-sm dark:border-zinc-700 dark:bg-zinc-900/60 dark:text-zinc-100"
                ]}
              >
                Global
              </button>
              <button
                type="button"
                phx-click="select_task_tab"
                phx-value-tab="by_client"
                class={[
                  "relative -mb-px rounded-t-md border px-4 py-2 text-xs font-semibold",
                  @selected_task_tab == "by_client" &&
                    "z-10 border-zinc-200 border-b-0 bg-white text-zinc-900 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-100",
                  @selected_task_tab != "by_client" &&
                    "mt-1 border-amber-200 bg-amber-100 text-amber-900 shadow-sm dark:border-zinc-700 dark:bg-zinc-900/60 dark:text-zinc-100"
                ]}
              >
                By Client/Contact
              </button>
            </div>
          </div>
          <div class="mx-4 mb-4 min-w-0 rounded-b-lg rounded-tr-lg border border-zinc-200 bg-white dark:border-zinc-800 dark:bg-zinc-900">
            <div class="overflow-auto max-h-[65vh]">
              <%= if @selected_task_tab == "global" do %>
              <table class="min-w-[1400px] w-full text-xs text-zinc-700 dark:text-zinc-200">
                <thead class="sticky top-0 z-20 bg-zinc-50 dark:bg-zinc-950">
                  <tr class="text-[11px] uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
                    <th class="sticky left-0 z-30 bg-zinc-50 dark:bg-zinc-950 px-2 py-1.5 text-left" style="width: 64px;">Rank</th>
                    <th class="sticky z-30 bg-zinc-50 dark:bg-zinc-950 px-2 py-1.5 text-left" style="left: 64px; width: 120px;">Client</th>
                    <th class="sticky z-30 bg-zinc-50 dark:bg-zinc-950 px-2 py-1.5 text-left" style="left: 184px; width: 260px;">Action</th>
                    <th class="px-2 py-1.5 text-left">Contact</th>
                    <th class="px-2 py-1.5 text-left">Status</th>
                    <th class="px-2 py-1.5 text-left">Remaining</th>
                    <th class="px-2 py-1.5 text-left">Commentary</th>
                    <th class="px-2 py-1.5 text-left">Next Action</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for {task, idx} <- ordered_tasks(@tasks) |> Enum.with_index() do %>
                    <% selected = task.id == @selected_task_id %>
                    <% zebra = rem(idx, 2) == 0 %>
                    <% base_bg = if zebra, do: "bg-white dark:bg-zinc-900", else: "bg-zinc-50 dark:bg-zinc-950" %>
                    <% row_bg = if selected, do: ["bg-indigo-100/60 dark:bg-indigo-500/35"], else: [base_bg] %>
                    <tr
                      phx-click="select_task"
                      phx-value-id={task.id}
                      class={[
                        "border-t border-zinc-200 dark:border-zinc-800",
                        row_bg
                      ]}
                    >
                      <td class={["sticky left-0 z-10 px-3 py-2", row_bg]} style="width: 64px;">
                        <div class="flex flex-col items-center gap-1 text-[10px] font-semibold tabular-nums">
                          <input
                            type="number"
                            name="rank"
                            value={task.priority}
                            min="1"
                            max={length(@tasks)}
                            phx-blur="update_rank"
                            phx-change="update_rank"
                            phx-value-id={task.id}
                            class="w-10 rounded border border-zinc-200 bg-transparent text-center text-[10px] font-semibold tabular-nums text-zinc-600 outline-none [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none focus:border-indigo-400 focus:bg-white focus:ring-1 focus:ring-indigo-400 dark:border-zinc-700 dark:bg-transparent dark:text-zinc-200 dark:focus:bg-zinc-900"
                          />
                        </div>
                      </td>
                      <td class={["sticky z-10 px-2 py-1 text-xs", row_bg]} style="left: 64px; width: 120px;">
                        <%= task.client.short_name %>
                      </td>
                      <td class={["sticky z-10 px-2 py-1 text-xs", row_bg]} style="left: 184px; width: 260px;">
                        <input
                          type="text"
                          value={task.title}
                          phx-blur="update_task_field"
                          phx-value-id={task.id}
                          phx-value-field="title"
                          name="value"
                          class="w-full rounded border border-transparent bg-transparent px-1 text-xs font-semibold text-zinc-900 outline-none focus:border-indigo-400 focus:bg-white dark:text-zinc-100 dark:focus:bg-zinc-900"
                        />
                      </td>
                      <td class={["px-2 py-1 text-xs", row_bg]} title="">
                        <span title=""><%= task.contact && task.contact.name || "—" %></span>
                      </td>
                      <td class={["px-2 py-1 text-xs", row_bg]}>
                        <select
                          name="value"
                          phx-blur="update_task_field"
                          phx-value-id={task.id}
                          phx-value-field="status"
                          class="w-28 rounded border border-zinc-200 bg-transparent px-1 py-0.5 text-[11px] font-semibold text-zinc-800 outline-none focus:border-indigo-400 focus:bg-white focus:ring-1 focus:ring-indigo-400 dark:border-zinc-700 dark:text-zinc-100 dark:focus:bg-zinc-900"
                        >
                          <%= for {label, value} <- status_options() do %>
                            <option value={value} selected={value == status_value(task.status)}><%= label %></option>
                          <% end %>
                        </select>
                      </td>
                      <td class={["px-3 py-2 text-xs", row_bg]}>
                        <input
                          type="number"
                          value={task.remaining_estimate_minutes || ""}
                          phx-blur="update_task_field"
                          phx-value-id={task.id}
                          phx-value-field="remaining_estimate_minutes"
                          name="value"
                          class="w-16 rounded border border-transparent bg-transparent px-1 text-xs text-zinc-700 outline-none [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none focus:border-indigo-400 focus:bg-white dark:text-zinc-200 dark:focus:bg-zinc-900"
                        />
                      </td>
                      <td class={["px-3 py-2 text-xs", row_bg]}>
                        <textarea
                          rows="2"
                          phx-blur="update_task_field"
                          phx-value-id={task.id}
                          phx-value-field="commentary"
                          name="value"
                          class="w-64 resize-none rounded border border-zinc-200 bg-transparent px-2 py-1 text-xs text-zinc-700 outline-none focus:border-indigo-400 focus:bg-white focus:ring-1 focus:ring-indigo-400 dark:border-zinc-800 dark:text-zinc-200 dark:focus:bg-zinc-900"
                        ><%= task.commentary %></textarea>
                      </td>
                      <td class={["px-3 py-2 text-xs", row_bg]}>
                        <textarea
                          rows="2"
                          phx-blur="update_task_field"
                          phx-value-id={task.id}
                          phx-value-field="next_action"
                          name="value"
                          class="w-64 resize-none rounded border border-zinc-200 bg-transparent px-2 py-1 text-xs text-zinc-700 outline-none focus:border-indigo-400 focus:bg-white focus:ring-1 focus:ring-indigo-400 dark:border-zinc-800 dark:text-zinc-200 dark:focus:bg-zinc-900"
                        ><%= task.next_action %></textarea>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            <% else %>
              <div class="px-4 py-4 space-y-4 text-sm">
              <%= for {client_name, contacts} <- tasks_by_client(@tasks) do %>
                <div class="space-y-2">
                  <div class="text-xs font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400"><%= client_name %></div>
                  <%= for {contact_name, tasks} <- contacts do %>
                    <div class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2 dark:border-zinc-800 dark:bg-zinc-950">
                      <div class="text-xs font-semibold text-zinc-700 dark:text-zinc-200"><%= contact_name %></div>
                      <div class="mt-2 space-y-2">
                        <%= for task <- tasks do %>
                          <button
                            type="button"
                            phx-click="select_task"
                            phx-value-id={task.id}
                            class="w-full text-left"
                          >
                            <div class="flex flex-wrap items-center justify-between gap-2 text-xs">
                              <div class="font-semibold text-zinc-900 dark:text-zinc-100">#<%= task.priority %> <%= task.title %></div>
                              <div class="text-zinc-500 dark:text-zinc-400"><%= status_label(task.status) %> · <%= task.remaining_estimate_minutes || "—" %>m</div>
                            </div>
                            <%= if task.status == :blocked do %>
                              <div class="text-[10px] text-rose-600 dark:text-rose-300">
                                <%= block_category_label(task.block_category) %> · <%= task.block_detail || "Blocked" %>
                              </div>
                            <% end %>
                          </button>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
              </div>
            <% end %>
            </div>
          </div>
        </div>

        <aside
          :if={@notes_drawer_open}
          class="w-full xl:w-[360px] xl:shrink-0 rounded-lg border border-zinc-200 bg-white shadow-sm dark:border-zinc-800 dark:bg-zinc-900"
        >
          <div class="border-b border-zinc-200 px-3 py-2 dark:border-zinc-800">
            <div class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">Task detail</div>
            <div class="text-xs text-zinc-500 dark:text-zinc-400">Work log + communications log.</div>
          </div>
          <%= if selected_task = selected_task(@tasks, @selected_task_id) do %>
            <div class="px-3 py-3 space-y-3">
              <div class="text-sm font-semibold text-zinc-900 dark:text-zinc-100"><%= selected_task.title %></div>
              <div class="text-xs text-zinc-500 dark:text-zinc-400">
                <%= selected_task.client.name %> · <%= selected_task.contact && selected_task.contact.name || "—" %> · #<%= selected_task.priority %>
              </div>

              <div class="grid grid-cols-2 gap-2 text-[11px] text-zinc-600 dark:text-zinc-300">
                <label class="space-y-1">
                  <span class="uppercase tracking-wide text-[10px]">Estimated (min)</span>
                  <input
                    type="number"
                    value={selected_task.estimated_minutes || ""}
                    phx-blur="update_task_field"
                    phx-value-id={selected_task.id}
                    phx-value-field="estimated_minutes"
                    name="value"
                    class="w-full rounded border border-zinc-200 bg-white px-2 py-1 text-xs text-zinc-700 outline-none [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-200"
                  />
                </label>
                <label class="space-y-1">
                  <span class="uppercase tracking-wide text-[10px]">Remaining (min)</span>
                  <input
                    type="number"
                    value={selected_task.remaining_estimate_minutes || ""}
                    phx-blur="update_task_field"
                    phx-value-id={selected_task.id}
                    phx-value-field="remaining_estimate_minutes"
                    name="value"
                    class="w-full rounded border border-zinc-200 bg-white px-2 py-1 text-xs text-zinc-700 outline-none [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-200"
                  />
                </label>
              </div>
              <div class="text-[11px] font-semibold text-zinc-600 dark:text-zinc-300">
                Elapsed time: <span class="text-zinc-900 dark:text-zinc-100"><%= elapsed_minutes(selected_task.time_entries) %> min</span>
              </div>
              <%= if selected_task.status == :blocked do %>
                <div class="rounded-md border border-rose-200 bg-rose-50/70 px-3 py-2 text-[11px] text-rose-700 dark:border-rose-700/40 dark:bg-rose-500/10 dark:text-rose-200">
                  <div class="font-semibold uppercase tracking-wide text-[10px]"><%= block_category_label(selected_task.block_category) %></div>
                  <div class="mt-2 space-y-2">
                    <input
                      type="text"
                      value={selected_task.block_detail || ""}
                      phx-blur="update_task_field"
                      phx-value-id={selected_task.id}
                      phx-value-field="block_detail"
                      name="value"
                      class="w-full rounded border border-rose-200 bg-white px-2 py-1 text-[11px] text-rose-700 outline-none focus:border-rose-300 focus:ring-1 focus:ring-rose-300 dark:border-rose-700/40 dark:bg-zinc-900 dark:text-rose-200"
                    />
                    <select
                      name="value"
                      phx-blur="update_task_field"
                      phx-value-id={selected_task.id}
                      phx-value-field="block_category"
                      class="w-full rounded border border-rose-200 bg-white px-2 py-1 text-[11px] text-rose-700 outline-none focus:border-rose-300 focus:ring-1 focus:ring-rose-300 dark:border-rose-700/40 dark:bg-zinc-900 dark:text-rose-200"
                    >
                      <%= for {label, value} <- block_category_options() do %>
                        <option value={value} selected={value == block_category_value(selected_task.block_category)}><%= label %></option>
                      <% end %>
                    </select>
                  </div>
                </div>
              <% end %>

              <div class="flex gap-2">
                <button
                  type="button"
                  phx-click="select_tab"
                  phx-value-tab="work"
                  class={["rounded-full px-3 py-1 text-xs font-semibold", @selected_tab == "work" && "bg-indigo-500 text-white", @selected_tab != "work" && "bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-300"]}
                >Work Log</button>
                <button
                  type="button"
                  phx-click="select_tab"
                  phx-value-tab="comms"
                  class={["rounded-full px-3 py-1 text-xs font-semibold", @selected_tab == "comms" && "bg-indigo-500 text-white", @selected_tab != "comms" && "bg-zinc-100 text-zinc-600 dark:bg-zinc-800 dark:text-zinc-300"]}
                >Communications Log</button>
              </div>

              <div class="space-y-3">
                <%= for entry <- log_entries(selected_task, @selected_tab) do %>
                  <div class="rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2 text-xs text-zinc-700 dark:border-zinc-800 dark:bg-zinc-950 dark:text-zinc-200">
                    <div class="text-[10px] font-semibold text-zinc-500 dark:text-zinc-400">
                      <%= format_timestamp(entry.occurred_at) %> · <%= entry.author %>
                    </div>
                    <div class="mt-1"><%= entry.body %></div>
                  </div>
                <% end %>
              </div>

              <div class="rounded-md border border-dashed border-zinc-300 p-3 dark:border-zinc-700">
                <form phx-submit="add_log_entry" class="space-y-2">
                  <input type="hidden" name="task_id" value={selected_task.id} />
                  <input type="hidden" name="type" value={@selected_tab} />
                  <div class="flex gap-2">
                    <input
                      type="text"
                      name="author"
                      value="Michael"
                      class="w-24 rounded border border-zinc-200 bg-white px-2 py-1 text-xs text-zinc-700 outline-none focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 dark:border-zinc-800 dark:bg-zinc-950 dark:text-zinc-200"
                    />
                    <div class="text-[10px] text-zinc-500 dark:text-zinc-400 self-center">author</div>
                  </div>
                  <textarea
                    rows="3"
                    name="body"
                    value={log_draft(@log_drafts, selected_task.id, @selected_tab)}
                    phx-change="update_log_draft"
                    phx-value-id={selected_task.id}
                    phx-value-type={@selected_tab}
                    class="w-full resize-none rounded border border-zinc-200 bg-white px-2 py-1 text-xs text-zinc-700 outline-none focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 dark:border-zinc-800 dark:bg-zinc-950 dark:text-zinc-200"
                    placeholder="Add a quick log entry..."
                  ><%= log_draft(@log_drafts, selected_task.id, @selected_tab) %></textarea>
                  <button
                    type="submit"
                    class="rounded bg-indigo-500 px-3 py-1 text-xs font-semibold text-white hover:bg-indigo-600"
                  >Add entry</button>
                </form>
              </div>

              <div class="space-y-2">
                <div class="text-xs font-semibold text-zinc-700 dark:text-zinc-200">Time entries</div>
                <%= for entry <- Enum.sort_by(selected_task.time_entries, & &1.ended_at, {:desc, DateTime}) do %>
                  <div class="rounded-md border border-zinc-200 bg-zinc-50 p-2 text-xs dark:border-zinc-800 dark:bg-zinc-950">
                    <%= if @editing_time_entry_id == entry.id do %>
                      <form phx-submit="save_time_entry" class="space-y-2">
                        <input type="hidden" name="entry_id" value={entry.id} />
                        <div class="grid grid-cols-2 gap-2">
                          <input
                            type="number"
                            name="duration_minutes"
                            value={duration_minutes(entry)}
                            class="w-full rounded border border-zinc-200 bg-white px-2 py-1 text-xs text-zinc-700 outline-none [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-200"
                          />
                          <label class="inline-flex items-center gap-1 text-[10px] text-zinc-600 dark:text-zinc-300">
                            <input type="checkbox" name="billable" value="true" checked={entry.billable} />
                            billable
                          </label>
                        </div>
                        <input
                          type="text"
                          name="note"
                          value={entry.note}
                          class="w-full rounded border border-zinc-200 bg-white px-2 py-1 text-xs text-zinc-700 outline-none focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-200"
                        />
                        <div class="flex gap-2">
                          <button type="submit" class="rounded bg-indigo-500 px-2 py-1 text-[10px] font-semibold text-white">Save</button>
                          <button type="button" phx-click="cancel_edit_time_entry" class="rounded border border-zinc-200 px-2 py-1 text-[10px] font-semibold text-zinc-600 dark:border-zinc-700 dark:text-zinc-300">Cancel</button>
                        </div>
                      </form>
                    <% else %>
                      <button
                        type="button"
                        phx-click="start_edit_time_entry"
                        phx-value-id={entry.id}
                        class="w-full text-left"
                      >
                        <div class="flex items-center justify-between gap-2">
                          <div class="font-semibold text-zinc-700 dark:text-zinc-200"><%= duration_minutes(entry) %> min</div>
                          <div class="text-[10px] text-zinc-400"><%= if entry.billable, do: "billable", else: "non-billable" %></div>
                        </div>
                        <div class="mt-1 text-[11px] text-zinc-600 dark:text-zinc-300"><%= entry.note || "No note" %></div>
                      </button>
                    <% end %>
                  </div>
                <% end %>
                <div class="rounded-md border border-dashed border-zinc-300 p-2 dark:border-zinc-700">
                  <form phx-submit="add_time_entry" class="space-y-2">
                    <input type="hidden" name="task_id" value={selected_task.id} />
                    <div class="grid grid-cols-2 gap-2">
                      <input
                        type="number"
                        name="duration_minutes"
                        placeholder="Minutes"
                        class="w-full rounded border border-zinc-200 bg-white px-2 py-1 text-xs text-zinc-700 outline-none [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-200"
                      />
                      <label class="inline-flex items-center gap-1 text-[10px] text-zinc-600 dark:text-zinc-300">
                        <input type="checkbox" name="billable" value="true" />
                        billable
                      </label>
                    </div>
                    <input
                      type="text"
                      name="note"
                      placeholder="Note"
                      class="w-full rounded border border-zinc-200 bg-white px-2 py-1 text-xs text-zinc-700 outline-none focus:border-indigo-400 focus:ring-1 focus:ring-indigo-400 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-200"
                    />
                    <button type="submit" class="rounded bg-indigo-500 px-2 py-1 text-[10px] font-semibold text-white">Add entry</button>
                  </form>
                </div>
              </div>
            </div>
          <% else %>
            <div class="px-4 py-6 text-sm text-zinc-500 dark:text-zinc-400">Select a row to see logs.</div>
          <% end %>
        </aside>
      </div>

    </div>
    """
  end

  defp load_tasks do
    Repo.all(
      from t in Task,
        order_by: t.priority,
        preload: [:contact, :time_entries, client: :activity_log_entries]
    )
  end

  defp reload_tasks(socket) do
    tasks = load_tasks()
    selected_task_id = socket.assigns.selected_task_id
    selected_task_id = if Enum.any?(tasks, &(&1.id == selected_task_id)), do: selected_task_id, else: tasks |> List.first() |> then(& &1 && &1.id)
    assign(socket, tasks: tasks, selected_task_id: selected_task_id)
  end

  defp ordered_tasks(tasks), do: Enum.sort_by(tasks, & &1.priority)

  defp selected_task(_tasks, nil), do: nil
  defp selected_task(tasks, id), do: Enum.find(tasks, &(&1.id == id))

  defp find_task(tasks, id), do: Enum.find(tasks, &(&1.id == id))

  defp reorder_priorities(target_rank, task_id) do
    tasks = Repo.all(from t in Task, order_by: t.priority)
    total = length(tasks)
    target_index = max(0, min(target_rank - 1, total - 1))
    current_index = Enum.find_index(tasks, &(&1.id == task_id))

    if is_nil(current_index) do
      :noop
    else
      {task, rest} = List.pop_at(tasks, current_index)
      reordered = List.insert_at(rest, target_index, task)

      Repo.transaction(fn ->
        Repo.update_all(Task, inc: [priority: total + 10])
        Enum.with_index(reordered, 1)
        |> Enum.each(fn {task, rank} ->
          Repo.update_all(from(t in Task, where: t.id == ^task.id), set: [priority: rank])
        end)
      end)
    end
  end

  defp task_updates(task, field, value) do
    case field do
      "title" -> {:ok, %{title: value}}
      "commentary" -> {:ok, %{commentary: value}}
      "next_action" -> {:ok, %{next_action: value}}
      "status" -> {:ok, %{status: status_atom(value), blocked_since: maybe_blocked_since(task, value)}}
      "block_detail" -> {:ok, %{block_detail: blank_to_nil(value)}}
      "block_category" -> {:ok, %{block_category: block_category_atom(value)}}
      "estimated_minutes" -> integer_update(:estimated_minutes, value)
      "remaining_estimate_minutes" -> integer_update(:remaining_estimate_minutes, value)
      _ -> {:error, :ignored}
    end
  end

  defp integer_update(field, value) do
    case parse_integer(value) do
      {:ok, int} -> {:ok, %{field => int}}
      _ -> {:ok, %{field => nil}}
    end
  end

  defp status_options do
    [
      {"Not Started", "not_started"},
      {"In Progress", "in_progress"},
      {"Blocked", "blocked"},
      {"Done", "done"}
    ]
  end

  defp status_value(nil), do: ""
  defp status_value(value) when is_atom(value), do: Atom.to_string(value)
  defp status_value(value), do: to_string(value)

  defp status_label(value) do
    status_options()
    |> Enum.find_value(status_value(value), fn {label, val} -> if val == status_value(value), do: label end)
  end

  defp status_atom(value) when is_atom(value), do: value
  defp status_atom(value) do
    case to_string(value) do
      "not_started" -> :not_started
      "in_progress" -> :in_progress
      "blocked" -> :blocked
      "done" -> :done
      _ -> :not_started
    end
  end

  defp block_category_options do
    [
      {"Awaiting handoff (internal)", "awaiting_handoff_internal"},
      {"Awaiting handoff (external)", "awaiting_handoff_external"},
      {"Awaiting research", "awaiting_research"}
    ]
  end

  defp block_category_value(nil), do: ""
  defp block_category_value(value) when is_atom(value), do: Atom.to_string(value)
  defp block_category_value(value), do: to_string(value)

  defp block_category_atom(value) do
    case to_string(value) do
      "awaiting_handoff_internal" -> :awaiting_handoff_internal
      "awaiting_handoff_external" -> :awaiting_handoff_external
      "awaiting_research" -> :awaiting_research
      _ -> nil
    end
  end

  defp block_category_label(value) do
    block_category_options()
    |> Enum.find_value("Blocked", fn {label, val} -> if val == block_category_value(value), do: label end)
  end

  defp log_kind("work"), do: :work
  defp log_kind("comms"), do: :comms
  defp log_kind(_), do: :work

  defp log_entries(task, tab) do
    kind = log_kind(tab)

    task.client.activity_log_entries
    |> Enum.filter(&(&1.kind == kind))
    |> Enum.sort_by(& &1.occurred_at, {:desc, DateTime})
  end

  defp log_draft(drafts, id, type), do: Map.get(drafts, "#{id}:#{type}", "")

  defp tasks_by_client(tasks) do
    tasks
    |> Enum.group_by(& &1.client.name)
    |> Enum.map(fn {client, items} ->
      contacts =
        items
        |> Enum.group_by(fn item -> item.contact && item.contact.name || "Unassigned" end)
        |> Enum.map(fn {contact, contact_tasks} ->
          {contact, Enum.sort_by(contact_tasks, & &1.priority)}
        end)
        |> Enum.sort_by(fn {contact, _} -> contact end)

      {client, contacts}
    end)
    |> Enum.sort_by(fn {client, _} -> client end)
  end

  defp format_timestamp(%DateTime{} = dt) do
    dt
    |> DateTime.truncate(:second)
    |> Calendar.strftime("%Y-%m-%d %H:%M")
  end

  defp elapsed_minutes(entries) do
    entries
    |> Enum.map(&duration_minutes/1)
    |> Enum.sum()
  end

  defp duration_minutes(%TimeEntry{} = entry) do
    DateTime.diff(entry.ended_at, entry.started_at, :second)
    |> div(60)
  end

  defp wip_cap(tasks) do
    active =
      tasks
      |> Enum.map(& &1.client)
      |> Enum.uniq_by(& &1.id)
      |> Enum.count(fn client -> client.stage in [:prospect, :proposal] end)

    {active, @wip_cap}
  end

  defp parse_integer(value) do
    case Integer.parse(to_string(value || "")) do
      {int, _} -> {:ok, int}
      _ -> {:error, :invalid}
    end
  end

  defp parse_id(value) do
    case parse_integer(value) do
      {:ok, int} -> int
      _ -> nil
    end
  end

  defp checkbox_value(value) do
    value in ["true", "on", true]
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp maybe_blocked_since(task, value) do
    status = status_atom(value)

    cond do
      status == :blocked and is_nil(task.blocked_since) -> DateTime.utc_now()
      status != :blocked -> nil
      true -> task.blocked_since
    end
  end
end
