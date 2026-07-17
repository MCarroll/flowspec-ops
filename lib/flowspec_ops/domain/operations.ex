defmodule FlowspecOps.Domain.Operations do
  @moduledoc """
  Cross-domain operations metadata for the ops.flowspec.co domain model.
  """

  @domain_model "ops.flowspec.co"
  @flow_lenses ["rules-of-flow", "pfep", "throughput-accounting"]

  @spec ping() :: map()
  def ping do
    %{
      domain_model: @domain_model,
      status: "ok"
    }
  end

  @spec system_status() :: map()
  def system_status do
    %{
      domain_model: @domain_model,
      flow_lenses: @flow_lenses,
      services: %{
        orders: "enabled",
        queue: "enabled"
      }
    }
  end
end
