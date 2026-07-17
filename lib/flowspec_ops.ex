defmodule FlowspecOps do
  @moduledoc """
  FlowspecOps keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias FlowspecOps.Domain.Operations

  @spec cli_status() :: map()
  def cli_status do
    Operations.system_status()
  end

  @spec cli_ping() :: map()
  def cli_ping do
    Operations.ping()
  end
end
