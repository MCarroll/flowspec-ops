defmodule FlowspecOps.Domain.Intake do
  @moduledoc """
  Unified intake capture service for ops.flowspec.co.
  """
  import Ecto.Query, only: [from: 2]
  alias FlowspecOps.Repo
  alias FlowspecOps.Sales.{Client, Contact, Task}

  @allowed_statuses ~w(active blocked waiting done)
  @part_context_fields ~w(project_ref master_assembly intake_group part_name)

  @spec capture(map()) :: {:ok, map()} | {:error, map()}
  def capture(payload) do
    with {:ok, normalized_payload} <- normalize_payload(payload),
         :ok <- validate_part_context(normalized_payload),
         {:ok, tasks} <- validate_tasks(payload["tasks"] || []),
         {:ok, persisted} <- persist_capture(normalized_payload, tasks) do
      {:ok, build_capture(normalized_payload, tasks, persisted)}
    end
  end

  defp normalize_payload(payload) do
    client_ref = String.trim(payload["client_ref"] || "")
    inbox = String.trim(payload["inbox"] || "")
    normalized_ref = if client_ref == "", do: "inbox", else: client_ref
    normalized_inbox = if normalized_ref == "inbox", do: default_inbox(inbox), else: inbox

    if normalized_ref == "inbox" and normalized_inbox == "" do
      {:error, %{code: "missing_field", message: "client_ref or inbox is required"}}
    else
      {:ok,
       payload
       |> Map.put("client_ref", normalized_ref)
       |> Map.put("inbox", normalized_inbox)}
    end
  end


  defp default_inbox(""), do: "general"
  defp default_inbox(value), do: value

  defp validate_part_context(payload) do
    present =
      @part_context_fields
      |> Enum.filter(fn field -> String.trim(payload[field] || "") != "" end)

    cond do
      present == [] ->
        :ok

      length(present) == length(@part_context_fields) ->
        :ok

      true ->
        missing =
          @part_context_fields
          |> Enum.reject(&(&1 in present))
          |> Enum.join(", ")

        {:error, %{code: "missing_field", message: "part context requires: #{missing}"}}
    end
  end

  defp validate_tasks([]),
    do: {:error, %{code: "missing_tasks", message: "at least one task is required"}}

  defp validate_tasks(tasks) when is_list(tasks) do
    tasks
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {task, idx}, {:ok, acc} ->
      case normalize_task(task, idx) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      error -> error
    end
  end

  defp validate_tasks(_),
    do: {:error, %{code: "invalid_tasks", message: "tasks must be a list"}}

  defp normalize_task(task, idx) do
    title = String.trim(task["action_title"] || "")
    commentary = String.trim(task["commentary"] || "")
    next_action = String.trim(task["next_action"] || "")
    status = String.trim(task["status"] || "")
    priority_rank = task["priority_rank"]

    cond do
      title == "" ->
        {:error, %{code: "invalid_task", message: "task #{idx}: action_title is required"}}

      commentary == "" ->
        {:error, %{code: "invalid_task", message: "task #{idx}: commentary is required"}}

      next_action == "" ->
        {:error, %{code: "invalid_task", message: "task #{idx}: next_action is required"}}

      status not in @allowed_statuses ->
        {:error,
         %{
           code: "invalid_task",
           message:
             "task #{idx}: status must be one of #{Enum.join(@allowed_statuses, ", ")}"
         }}

      not is_integer(priority_rank) ->
        {:error, %{code: "invalid_task", message: "task #{idx}: priority_rank must be integer"}}

      true ->
        {:ok,
         %{
           "task_id" => "task-#{idx}",
           "action_title" => title,
           "commentary" => commentary,
           "next_action" => next_action,
           "status" => status,
           "priority_rank" => priority_rank
         }}
    end
  end

  defp build_capture(payload, tasks, persisted) do
    capture_id = "intake-#{System.system_time(:millisecond)}"
    tasks_with_ids = attach_task_ids(tasks, capture_id, persisted.tasks)
    blocked_count = Enum.count(tasks_with_ids, &(&1["status"] == "blocked"))
    waiting_count = Enum.count(tasks_with_ids, &(&1["status"] == "waiting"))
    total_count = length(tasks_with_ids)
    part_context = build_part_context(payload)
    base = %{
      capture_id: capture_id,
      domain_model: "ops.flowspec.co",
      client: %{
        client_ref: payload["client_ref"],
        client_name: payload["client_name"] || payload["client_ref"],
        inbox: payload["inbox"]
      },
      contact: %{
        contact_name: payload["contact_name"],
        contact_email: payload["contact_email"]
      },
      counters: %{
        blocked: blocked_count,
        waiting: waiting_count,
        total_tasks: total_count
      },
      tasks: tasks_with_ids,
      records: %{
        client_id: persisted.client.id,
        contact_id: persisted.contact && persisted.contact.id
      }
    }

    if part_context == %{} do
      base
    else
      Map.put(base, :part_context, part_context)
    end
  end

  defp attach_task_ids(tasks, capture_id, persisted_tasks) do
    tasks
    |> Enum.with_index(1)
    |> Enum.map(fn {task, idx} ->
      persisted_task = Enum.at(persisted_tasks, idx - 1)
      task
      |> Map.put("task_id", "#{capture_id}-task-#{idx}")
      |> Map.put("capture_id", capture_id)
      |> Map.put("db_task_id", persisted_task && persisted_task.id)
    end)
  end

  defp build_part_context(payload) do
    %{
      project_ref: payload["project_ref"],
      master_assembly: payload["master_assembly"],
      intake_group: payload["intake_group"],
      part_name: payload["part_name"]
    }
    |> Enum.reject(fn {_key, value} -> String.trim(value || "") == "" end)
    |> Map.new()
  end

  defp persist_capture(payload, tasks) do
    Repo.transaction(fn ->
      client = ensure_client(payload)
      contact = ensure_contact(client, payload)
      persisted_tasks = persist_tasks(client, contact, tasks)
      %{client: client, contact: contact, tasks: persisted_tasks}
    end)
    |> case do
      {:ok, data} ->
        {:ok, data}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error,
         %{
           code: "persistence_failed",
           message: "intake persistence failed",
           details: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
         }}
    end
  end

  defp ensure_client(payload) do
    client_ref = String.trim(payload["client_ref"] || "")
    client_name = String.trim(payload["client_name"] || client_ref)

    existing =
      Repo.one(
        from c in Client,
          where: c.short_name == ^client_ref or c.name == ^client_name,
          limit: 1
      )

    case existing do
      nil ->
        %Client{}
        |> Client.changeset(%{
          name: client_name,
          short_name: client_ref,
          slug: slugify(client_ref),
          stage: :prospect,
          source: "intake.capture"
        })
        |> Repo.insert!()

      client ->
        maybe_update_client_name(client, client_name)
    end
  end

  defp maybe_update_client_name(client, ""), do: client

  defp maybe_update_client_name(client, name) do
    if client.name == name do
      client
    else
      client
      |> Client.changeset(%{name: name})
      |> Repo.update!()
    end
  end

  defp ensure_contact(client, payload) do
    contact_name = String.trim(payload["contact_name"] || "")
    contact_email = blank_to_nil(payload["contact_email"])

    if contact_name == "" do
      nil
    else
      existing =
        Repo.one(
          from c in Contact,
            where: c.client_id == ^client.id and c.name == ^contact_name,
            limit: 1
        )

      case existing do
        nil ->
          %Contact{}
          |> Contact.changeset(%{
            client_id: client.id,
            name: contact_name,
            role: "primary_contact",
            email: contact_email
          })
          |> Repo.insert!()

        contact ->
          maybe_update_contact_email(contact, contact_email)
      end
    end
  end

  defp maybe_update_contact_email(contact, nil), do: contact

  defp maybe_update_contact_email(contact, email) do
    if contact.email == email do
      contact
    else
      contact
      |> Contact.changeset(%{email: email})
      |> Repo.update!()
    end
  end

  defp persist_tasks(client, contact, tasks) do
    start_priority = next_priority()

    tasks
    |> Enum.with_index(start_priority)
    |> Enum.map(fn {task, priority} ->
      attrs = %{
        client_id: client.id,
        contact_id: contact && contact.id,
        title: task["action_title"],
        commentary: task["commentary"],
        next_action: task["next_action"],
        status: task_status(task["status"]),
        priority: priority
      }

      %Task{}
      |> Task.changeset(attrs)
      |> Repo.insert!()
    end)
  end

  defp next_priority do
    (Repo.one(from t in Task, select: max(t.priority)) || 0) + 1
  end

  defp task_status("active"), do: :in_progress
  defp task_status("blocked"), do: :blocked
  defp task_status("waiting"), do: :not_started
  defp task_status("done"), do: :done

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp slugify(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end
end
