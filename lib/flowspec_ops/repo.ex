defmodule FlowspecOps.Repo do
  use Ecto.Repo,
    otp_app: :flowspec_ops,
    adapter: Ecto.Adapters.Postgres
end
