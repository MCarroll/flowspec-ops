defmodule FlowspecOps.Domain.Orders do
  @moduledoc """
  Order-domain service entry points used by LiveView, API adapters, and CLI.
  """

  @spec create(map()) :: {:ok, map()} | {:error, map()}
  def create(%{"order_ref" => order_ref}) when is_binary(order_ref) and order_ref != "" do
    {:ok,
     %{
       order_ref: order_ref,
       status: "queued"
     }}
  end

  def create(_params) do
    {:error,
     %{
       code: "invalid_order",
       message: "order_ref is required"
     }}
  end
end
