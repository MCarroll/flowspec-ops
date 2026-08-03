defmodule FlowspecOps.Repo.Migrations.AddQtyToFactoryNodeSteps do
  use Ecto.Migration

  def change do
    alter table(:factory_node_steps) do
      add :qty_per_unit, :integer
      add :minutes_each, :integer
    end
  end
end
