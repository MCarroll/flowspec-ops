defmodule FlowspecOps.Repo.Migrations.AddSharedToFactoryNodeSteps do
  use Ecto.Migration

  def change do
    alter table(:factory_node_steps) do
      add :shared, :boolean, default: true, null: false
    end
  end
end
