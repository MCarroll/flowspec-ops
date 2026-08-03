defmodule FlowspecOps.Repo.Migrations.AddSpecsToFactoryNodeSteps do
  use Ecto.Migration

  def change do
    alter table(:factory_node_steps) do
      add :specs, :text
    end
  end
end
