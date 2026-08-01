defmodule FlowspecOps.Repo.Migrations.CreateFactoryNodesAndSteps do
  use Ecto.Migration

  def change do
    create table(:factory_nodes) do
      add :factory_id, references(:factories, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :name, :string, null: false
      add :position, :integer, null: false
      add :bypass_allowed, :boolean, default: false, null: false
      add :note, :text

      timestamps()
    end

    create index(:factory_nodes, [:factory_id])
    create unique_index(:factory_nodes, [:factory_id, :position])

    create table(:factory_node_steps) do
      add :factory_node_id, references(:factory_nodes, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :position, :integer, null: false
      add :estimated_minutes, :integer

      timestamps()
    end

    create index(:factory_node_steps, [:factory_node_id])
    create unique_index(:factory_node_steps, [:factory_node_id, :position])
  end
end
