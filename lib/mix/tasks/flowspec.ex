defmodule Mix.Tasks.Flowspec do
  use Mix.Task

  @shortdoc "Flowspec CLI entry point for ops.flowspec.co domain services"

  @moduledoc """
  CLI entry point for FlowspecOps domain services.

  Usage:
    mix flowspec ping
    mix flowspec status
    mix flowspec order.create ORDER_REF
    mix flowspec queue.transition ORDER_REF TO_STATUS
    mix flowspec intake.capture --client-ref REF --client-name NAME --project-ref REF --master-assembly NAME --intake-group NAME --part-name NAME --action-title TITLE --status STATUS --commentary TEXT --next-action TEXT --priority-rank N
    mix flowspec intake.capture --client-ref REF --client-name NAME --task "TITLE|STATUS|COMMENTARY|NEXT_ACTION|PRIORITY"
  """

  alias FlowspecOps.Domain.Intake
  alias FlowspecOps.Domain.Orders
  alias FlowspecOps.Domain.Queue

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case args do
      ["ping"] ->
        FlowspecOps.cli_ping() |> print_ok()

      ["status"] ->
        FlowspecOps.cli_status() |> print_ok()

      ["order.create", order_ref] ->
        Orders.create(%{"order_ref" => order_ref}) |> print_result()

      ["queue.transition", order_ref, to_status] ->
        Queue.transition(%{"order_ref" => order_ref, "to_status" => to_status}) |> print_result()

      ["intake.capture" | intake_args] ->
        intake_args
        |> parse_intake_payload()
        |> Intake.capture()
        |> print_result()

      _ ->
        Mix.shell().info("""
        Usage:
          mix flowspec ping
          mix flowspec status
          mix flowspec order.create ORDER_REF
          mix flowspec queue.transition ORDER_REF TO_STATUS
          mix flowspec intake.capture --client-ref REF --client-name NAME --project-ref REF --master-assembly NAME --intake-group NAME --part-name NAME --action-title TITLE --status STATUS --commentary TEXT --next-action TEXT --priority-rank N
          mix flowspec intake.capture --client-ref REF --client-name NAME --task "TITLE|STATUS|COMMENTARY|NEXT_ACTION|PRIORITY"
        """)
    end
  end

  defp print_result({:ok, payload}), do: print_ok(payload)

  defp print_result({:error, payload}) do
    print_json(payload)
    Mix.raise("flowspec command failed")
  end

  defp print_ok(payload) do
    print_json(payload)
    :ok
  end

  defp print_json(payload) do
    Mix.shell().info(Jason.encode_to_iodata!(payload, pretty: true))
  end

  defp parse_intake_payload(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          client_ref: :string,
          inbox: :string,
          client_name: :string,
          project_ref: :string,
          master_assembly: :string,
          intake_group: :string,
          part_name: :string,
          contact_name: :string,
          contact_email: :string,
          action_title: :string,
          status: :string,
          commentary: :string,
          next_action: :string,
          priority_rank: :integer,
          task: :keep
        ]
      )

    tasks =
      opts
      |> Keyword.get_values(:task)
      |> Kernel.++(inline_task_from_opts(opts))

    %{
      "client_ref" => opts[:client_ref],
      "inbox" => opts[:inbox],
      "client_name" => opts[:client_name],
      "project_ref" => opts[:project_ref],
      "master_assembly" => opts[:master_assembly],
      "intake_group" => opts[:intake_group],
      "part_name" => opts[:part_name],
      "contact_name" => opts[:contact_name],
      "contact_email" => opts[:contact_email],
      "tasks" => Enum.map(tasks, &parse_task/1)
    }
  end

  defp parse_task(task_spec) do
    [title, status, commentary, next_action, priority_raw] =
      task_spec
      |> String.split("|", parts: 5)
      |> pad_task_parts()

    %{
      "action_title" => String.trim(title),
      "status" => String.trim(status),
      "commentary" => String.trim(commentary),
      "next_action" => String.trim(next_action),
      "priority_rank" => parse_priority(priority_raw)
    }
  end

  defp parse_priority(raw) do
    case Integer.parse(String.trim(raw || "")) do
      {value, ""} -> value
      _ -> -1
    end
  end

  defp pad_task_parts(parts) do
    parts ++ List.duplicate("", max(0, 5 - length(parts)))
  end

  defp inline_task_from_opts(opts) do
    title = String.trim(opts[:action_title] || "")
    status = String.trim(opts[:status] || "")
    commentary = String.trim(opts[:commentary] || "")
    next_action = String.trim(opts[:next_action] || "")
    priority_rank = opts[:priority_rank]

    if title == "" and status == "" and commentary == "" and next_action == "" and is_nil(priority_rank) do
      []
    else
      priority_text = if is_integer(priority_rank), do: Integer.to_string(priority_rank), else: ""
      [Enum.join([title, status, commentary, next_action, priority_text], "|")]
    end
  end
end
