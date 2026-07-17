defmodule FlowspecOpsWeb.ClientsLive do
  use FlowspecOpsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    clients = [
      %{
        id: "hhco",
        name: "Higher Health (HHCO)",
        blocked_tasks: 1,
        total_tasks: 3,
        contacts: [
          %{
            id: "max",
            name: "Max",
            role: "Primary Contact",
            tasks: [
              %{
                id: "hhco-task-1",
                primary_order: "HHCO-101",
                secondary_order: "PK-01",
                title: "Send CaliJane2 invite with visuals",
                commentary: "Invite is blocked pending visuals.",
                next_action: "Attach Graffle diagram and 3D press mold drawing, then send CaliJane2 invite email.",
                status: "Blocked",
                priority: 1,
                remaining_estimate: "45m"
              },
              %{
                id: "hhco-task-2",
                primary_order: "HHCO-101",
                secondary_order: "PK-02",
                title: "Create Graffle brand wiring",
                commentary: "Graffle document required to explain company/brand wiring.",
                next_action: "Create and export Graffle document for email attachment.",
                status: "In Progress",
                priority: 2,
                remaining_estimate: "2h"
              },
              %{
                id: "hhco-task-3",
                primary_order: "HHCO-101",
                secondary_order: "PK-03",
                title: "Finalize 3D press mold drawing",
                commentary: "3D press mold drawing needed for client communication packet.",
                next_action: "Finish drawing revision and export shareable file.",
                status: "In Progress",
                priority: 3,
                remaining_estimate: "3h"
              }
            ]
          }
        ]
      },
      %{
        id: "cascade-fabrication",
        name: "Cascade Fabrication",
        blocked_tasks: 2,
        total_tasks: 14,
        contacts: [
          %{
            id: "maya-reed",
            name: "Maya Reed",
            role: "Operations Lead",
            tasks: [
              %{
                id: "cf-task-1",
                primary_order: "CF-7782",
                secondary_order: "RTE-01",
                title: "Confirm routing approval window",
                commentary: "Awaiting approval on revised routing sequence.",
                next_action: "Confirm approval window with client.",
                status: "Blocked",
                priority: 1,
                remaining_estimate: "30m"
              },
              %{
                id: "cf-task-2",
                primary_order: "CF-7782",
                secondary_order: "SHIP-02",
                title: "Share dock slot proposal",
                commentary: "Needs updated shipping window.",
                next_action: "Share proposed dock slots.",
                status: "In Progress",
                priority: 3,
                remaining_estimate: "1h"
              }
            ]
          }
        ]
      },
      %{
        id: "sample-intake",
        name: "Sample Intake",
        blocked_tasks: 1,
        total_tasks: 4,
        contacts: [
          %{
            id: "jordan-lee",
            name: "Jordan Lee",
            role: "Intake Coordinator",
            tasks: [
              %{
                id: "si-task-1",
                primary_order: "SI-554",
                secondary_order: "INT-01",
                title: "Collect signed intake checklist",
                commentary: "Awaiting signed intake checklist from client.",
                next_action: "Send reminder with checklist link.",
                status: "Blocked",
                priority: 1,
                remaining_estimate: "20m"
              },
              %{
                id: "si-task-2",
                primary_order: "SI-554",
                secondary_order: "INT-02",
                title: "Draft intake routing",
                commentary: "Sample specs captured in notes.",
                next_action: "Create routing draft for review.",
                status: "In Progress",
                priority: 2,
                remaining_estimate: "90m"
              }
            ]
          }
        ]
      },
      %{
        id: "blue-harbor-foods",
        name: "Blue Harbor Foods",
        blocked_tasks: 0,
        total_tasks: 9,
        contacts: [
          %{
            id: "devon-clark",
            name: "Devon Clark",
            role: "Plant Scheduler",
            tasks: [
              %{
                id: "bh-task-1",
                primary_order: "BH-904",
                secondary_order: "PLAN-03",
                title: "Send staffing roster",
                commentary: "Confirmed blend plan for next week.",
                next_action: "Send final staffing roster.",
                status: "On Track",
                priority: 2,
                remaining_estimate: "40m"
              }
            ]
          }
        ]
      },
      %{
        id: "silverline-assembly",
        name: "Silverline Assembly",
        blocked_tasks: 3,
        total_tasks: 21,
        contacts: [
          %{
            id: "rafael-ortiz",
            name: "Rafael Ortiz",
            role: "Production Manager",
            tasks: [
              %{
                id: "sa-task-1",
                primary_order: "SA-2210",
                secondary_order: "TOOL-01",
                title: "Verify tooling ETA",
                commentary: "Awaiting tooling availability for line 4.",
                next_action: "Verify tooling ETA with vendor.",
                status: "Blocked",
                priority: 1,
                remaining_estimate: "1.5h"
              }
            ]
          }
        ]
      }
    ]

    {:ok,
     assign(socket,
       clients: clients,
       expanded_clients: MapSet.new(),
       expanded_contacts: MapSet.new(),
       page_title: "Clients",
       editing_task_for: nil
     )}
  end

  defp reorder_task_by_position(clients, client_id, contact_id, task_id, target_position) do
    Enum.map(clients, fn client ->
      if client.id == client_id do
        contacts =
          Enum.map(client.contacts, fn contact ->
            if contact.id == contact_id do
              %{contact | tasks: contact.tasks |> move_task_to_position(task_id, target_position) |> resequence_priorities()}
            else
              contact
            end
          end)

        %{client | contacts: contacts}
      else
        client
      end
    end)
  end
  @impl true
  def handle_event("toggle_client", %{"id" => id}, socket) do
    {:noreply, update(socket, :expanded_clients, &toggle_set(&1, id))}
  end

  @impl true
  def handle_event("toggle_contact", %{"id" => id}, socket) do
    {:noreply, update(socket, :expanded_contacts, &toggle_set(&1, id))}
  end
  @impl true
  def handle_event("start_edit_task_position", %{"client_id" => client_id, "contact_id" => contact_id, "task_id" => task_id}, socket) do
    {:noreply, assign(socket, :editing_task_for, %{client_id: client_id, contact_id: contact_id, task_id: task_id})}
  end

  @impl true
  def handle_event("save_task_position", params, socket) do
    case socket.assigns.editing_task_for do
      nil ->
        {:noreply, socket}

      %{client_id: client_id, contact_id: contact_id, task_id: task_id} ->
        raw_position = params["position"] || params["value"]

        if raw_position in [nil, ""] do
          {:noreply, assign(socket, :editing_task_for, nil)}
        else
          updated_clients =
            reorder_task_by_position(
              socket.assigns.clients,
              client_id,
              contact_id,
              task_id,
              String.to_integer(raw_position)
            )

          {:noreply,
           socket
           |> assign(:clients, updated_clients)
           |> assign(:editing_task_for, nil)}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-semibold text-zinc-900 dark:text-zinc-100">Clients</h1>
        <p class="text-sm text-zinc-600 dark:text-zinc-300">
          At-a-glance task health for each client.
        </p>
      </div>
      <% global_tasks = global_tasks(@clients) %>
      <div class="rounded-lg border border-zinc-200 bg-white shadow-sm dark:border-zinc-800 dark:bg-zinc-900">
        <div class="border-b border-zinc-200 px-4 py-3 dark:border-zinc-800">
          <div class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">Global task list</div>
          <div class="text-xs text-zinc-500 dark:text-zinc-400">All active client work, ordered by current priority.</div>
        </div>
        <div class="px-4 py-3">
          <div class="grid grid-cols-12 gap-3 text-[11px] font-semibold uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
            <div class="col-span-2">Primary</div>
            <div class="col-span-2">Secondary</div>
            <div class="col-span-3">Task</div>
            <div class="col-span-2">Client</div>
            <div class="col-span-1">Contact</div>
            <div class="col-span-1">Status</div>
            <div class="col-span-1 text-right">Remaining</div>
          </div>
          <div class="mt-2 space-y-2 text-sm">
            <%= for task <- global_tasks do %>
              <div class="grid grid-cols-12 items-center gap-3 rounded-md border border-zinc-200 bg-zinc-50 px-3 py-2 text-zinc-800 dark:border-zinc-800 dark:bg-zinc-950 dark:text-zinc-100">
                <div class="col-span-2 text-xs font-semibold text-zinc-600 dark:text-zinc-300"><%= task.primary_order %></div>
                <div class="col-span-2 text-xs font-semibold text-zinc-600 dark:text-zinc-300"><%= task.secondary_order %></div>
                <div class="col-span-3 truncate font-semibold"><%= task.title %></div>
                <div class="col-span-2 truncate text-xs text-zinc-600 dark:text-zinc-300"><%= task.client_name %></div>
                <div class="col-span-1 truncate text-xs text-zinc-600 dark:text-zinc-300"><%= task.contact_name %></div>
                <div class="col-span-1">
                  <div class={["rounded-full px-2 py-0.5 text-[10px] font-semibold text-center", status_badge_class(task.status)]}>
                    <%= task.status %>
                  </div>
                </div>
                <div class="col-span-1 text-right text-xs font-semibold text-zinc-700 dark:text-zinc-200"><%= task.remaining_estimate %></div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
      <div class="space-y-3">
        <%= for client <- @clients do %>
          <% client_open = MapSet.member?(@expanded_clients, client.id) %>
          <div class="rounded-lg border border-zinc-200 bg-white shadow-sm dark:border-zinc-800 dark:bg-zinc-900">
            <button
              type="button"
              phx-click="toggle_client"
              phx-value-id={client.id}
              class="flex w-full items-center justify-between gap-4 px-4 py-3 text-left"
            >
              <div>
                <div class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                  <%= client.name %>
                </div>
                <div class="mt-1 text-xs text-zinc-500 dark:text-zinc-400">
                  <%= if client_open, do: "Collapse", else: "Expand" %>
                </div>
              </div>
              <div class="flex items-center gap-4 text-sm">
                <div class="flex items-center gap-2 text-zinc-600 dark:text-zinc-300">
                  <span class="inline-flex h-2 w-2 rounded-full bg-amber-500"></span>
                  <span>Blocked: <%= client.blocked_tasks %></span>
                </div>
                <div class="text-zinc-600 dark:text-zinc-300">
                  Total: <%= client.total_tasks %>
                </div>
                <span class="text-xs text-zinc-400">
                  <%= if client_open, do: "▾", else: "▸" %>
                </span>
              </div>
            </button>

            <%= if client_open do %>
              <div class="border-t border-zinc-200 px-4 py-4 dark:border-zinc-800">
                <div class="space-y-3">
                  <%= for contact <- client.contacts do %>
                    <% contact_key = "#{client.id}-#{contact.id}" %>
                    <% contact_open = MapSet.member?(@expanded_contacts, contact_key) %>
                    <div class="rounded-md border border-zinc-200 bg-zinc-50 dark:border-zinc-800 dark:bg-zinc-950">
                      <button
                        type="button"
                        phx-click="toggle_contact"
                        phx-value-id={contact_key}
                        class="flex w-full items-center justify-between gap-4 px-4 py-3 text-left"
                      >
                        <div>
                          <div class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                            <%= contact.name %>
                          </div>
                          <div class="text-xs text-zinc-500 dark:text-zinc-400">
                            <%= contact.role %>
                          </div>
                        </div>
                        <span class="text-xs text-zinc-400">
                          <%= if contact_open, do: "▾", else: "▸" %>
                        </span>
                      </button>

                      <%= if contact_open do %>
                        <div class="border-t border-zinc-200 px-4 py-4 text-sm dark:border-zinc-800">
                          <div class="space-y-3">
                            <%= for task <- contact.tasks do %>
                              <% editing_task = @editing_task_for && @editing_task_for.task_id == task.id && @editing_task_for.contact_id == contact.id && @editing_task_for.client_id == client.id %>
                              <div class="group/row rounded-md border border-zinc-200 bg-white p-3 dark:border-zinc-800 dark:bg-zinc-900">
                                <div class="flex flex-wrap items-center justify-between gap-2">
                                  <div class="flex min-w-0 items-center gap-2">
                                    <%= if editing_task do %>
                                      <form phx-submit="save_task_position" class="contents">
                                        <input type="hidden" name="client_id" value={client.id} />
                                        <input type="hidden" name="contact_id" value={contact.id} />
                                        <input type="hidden" name="task_id" value={task.id} />
                                        <input
                                          type="number"
                                          name="position"
                                          value={task.priority}
                                          min="1"
                                          max={length(contact.tasks)}
                                          phx-blur="save_task_position"
                                          class="w-7 h-5 text-center text-[10px] font-semibold tabular-nums rounded border border-indigo-400 dark:border-indigo-500 bg-white dark:bg-zinc-900 text-indigo-600 dark:text-indigo-300 outline-none focus:ring-1 focus:ring-indigo-400 p-0"
                                        />
                                      </form>
                                    <% else %>
                                      <button
                                        type="button"
                                        phx-click="start_edit_task_position"
                                        phx-value-client_id={client.id}
                                        phx-value-contact_id={contact.id}
                                        phx-value-task_id={task.id}
                                        title="Click to reorder task"
                                        class="inline-flex h-5 w-7 items-center justify-center rounded-full border border-zinc-200 dark:border-zinc-700 text-[10px] font-semibold tabular-nums text-zinc-400 dark:text-zinc-500 hover:border-indigo-400 hover:text-indigo-600 dark:hover:border-indigo-500 dark:hover:text-indigo-300 transition-colors"
                                      >
                                        #<%= task.priority %>
                                      </button>
                                    <% end %>
                                    <div class="min-w-0 text-sm font-semibold text-zinc-900 dark:text-zinc-100 truncate">
                                      <%= task.title %>
                                    </div>
                                  </div>
                                  <div class="flex items-center gap-2">
                                    <div class={[
                                      "rounded-full px-2 py-0.5 text-xs font-semibold",
                                      status_badge_class(task.status)
                                    ]}>
                                      <%= task.status %>
                                    </div>
                                  </div>
                                </div>
                                <div class="mt-2 text-zinc-700 dark:text-zinc-200">
                                  <span class="font-semibold">Commentary:</span>
                                  <%= task.commentary %>
                                </div>
                                <div class="mt-2 text-zinc-700 dark:text-zinc-200">
                                  <span class="font-semibold">Next action:</span>
                                  <%= task.next_action %>
                                </div>
                              </div>
                            <% end %>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp toggle_set(set, id) do
    if MapSet.member?(set, id) do
      MapSet.delete(set, id)
    else
      MapSet.put(set, id)
    end
  end


  defp move_task_to_position(tasks, task_id, target_position) do
    total = length(tasks)
    target_position = max(1, min(target_position, total))
    current_index = Enum.find_index(tasks, &(&1.id == task_id))

    if is_nil(current_index) do
      tasks
    else
      {target, rest} = List.pop_at(tasks, current_index)
      List.insert_at(rest, target_position - 1, target)
    end
  end


  defp resequence_priorities(tasks) do
    tasks
    |> Enum.with_index(1)
    |> Enum.map(fn {task, rank} -> %{task | priority: rank} end)
  end

  defp status_badge_class("Blocked"), do: "bg-rose-100 text-rose-700 dark:bg-rose-500/20 dark:text-rose-200"
  defp status_badge_class("On Track"), do: "bg-emerald-100 text-emerald-700 dark:bg-emerald-500/20 dark:text-emerald-200"
  defp status_badge_class("In Progress"), do: "bg-amber-100 text-amber-700 dark:bg-amber-500/20 dark:text-amber-200"
  defp status_badge_class(_status), do: "bg-zinc-100 text-zinc-700 dark:bg-zinc-500/20 dark:text-zinc-200"

  defp global_tasks(clients) do
    for client <- clients,
        contact <- client.contacts,
        task <- contact.tasks do
      task
      |> Map.put(:client_name, client.name)
      |> Map.put(:contact_name, contact.name)
    end
  end
end
