defmodule FlowspecOps.Repo.Migrations.AddStepManningAndCrew do
  use Ecto.Migration

  def change do
    alter table(:factory_node_steps) do
      add :people, :integer
    end

    alter table(:factory_nodes) do
      add :crew_size, :integer
    end
  end
end
