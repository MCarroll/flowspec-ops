defmodule FlowspecOps.Repo.Migrations.AddStorageGroupToFactoryNodes do
  use Ecto.Migration

  def change do
    alter table(:factory_nodes) do
      add :storage_group, :string
    end

    create index(:factory_nodes, [:factory_id, :storage_group])
  end
end
