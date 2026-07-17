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
    mix flowspec intake.capture --client-ref REF --contact-name NAME --contact-email EMAIL --task "TITLE|STATUS|COMMENTARY|NEXT_ACTION|PRIORITY"
  """

  alias FlowspecOps.Domain.Intake
  alias FlowspecOps.Domain.Orders
  alias FlowspecOps.Domain.Queue

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.config")

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
          mix flowspec intake.capture --client-ref REF --client-name NAME --contact-name NAME --contact-email EMAIL --task "TITLE|STATUS|COMMENTARY|NEXT_ACTION|PRIORITY"
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
          client_name: :string,
          contact_name: :string,
          contact_email: :string,
          task: :keep
        ]
      )

    tasks = Keyword.get_values(opts, :task)

    %{
      "client_ref" => opts[:client_ref],
      "client_name" => opts[:client_name],
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
end
