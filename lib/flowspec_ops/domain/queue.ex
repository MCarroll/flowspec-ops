defmodule FlowspecOps.Domain.Queue do
  @moduledoc """
  Queue-domain service entry points used by LiveView, API adapters, and CLI.
  """

  @allowed_statuses ~w(queued in_progress ready completed held)

  @spec transition(map()) :: {:ok, map()} | {:error, map()}
  def transition(%{"order_ref" => order_ref, "to_status" => to_status})
      when is_binary(order_ref) and is_binary(to_status) do
    if to_status in @allowed_statuses do
      {:ok,
       %{
         order_ref: order_ref,
         to_status: to_status
       }}
    else
      {:error,
       %{
         code: "invalid_status",
         message: "to_status must be one of: #{Enum.join(@allowed_statuses, ", ")}"
       }}
    end
  end

  def transition(_params) do
    {:error,
     %{
       code: "invalid_transition",
       message: "order_ref and to_status are required"
     }}
  end
end
