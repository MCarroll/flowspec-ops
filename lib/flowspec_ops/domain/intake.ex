defmodule FlowspecOps.Domain.Intake do
  @moduledoc """
  Unified intake capture service for ops.flowspec.co.
  """

  @allowed_statuses ~w(active blocked waiting done)

  @spec capture(map()) :: {:ok, map()} | {:error, map()}
  def capture(payload) do
    with :ok <- validate_required(payload, "client_ref"),
         :ok <- validate_required(payload, "contact_name"),
         :ok <- validate_required(payload, "contact_email"),
         {:ok, tasks} <- validate_tasks(payload["tasks"] || []) do
      {:ok, build_capture(payload, tasks)}
    end
  end

  defp validate_required(payload, field) do
    case String.trim(payload[field] || "") do
      "" ->
        {:error, %{code: "missing_field", message: "#{field} is required"}}

      _ ->
        :ok
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

  defp build_capture(payload, tasks) do
    blocked_count = Enum.count(tasks, &(&1["status"] == "blocked"))
    waiting_count = Enum.count(tasks, &(&1["status"] == "waiting"))
    total_count = length(tasks)
    capture_id = "intake-#{System.system_time(:millisecond)}"

    %{
      capture_id: capture_id,
      domain_model: "ops.flowspec.co",
      client: %{
        client_ref: payload["client_ref"],
        client_name: payload["client_name"] || payload["client_ref"]
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
      tasks: tasks
    }
  end
end
