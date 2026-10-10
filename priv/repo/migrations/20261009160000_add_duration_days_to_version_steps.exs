defmodule FlowspecOps.Repo.Migrations.AddDurationDaysToVersionSteps do
  use Ecto.Migration

  def change do
    alter table(:factory_version_node_steps) do
      add :duration_days, :integer
    end
  end
end
