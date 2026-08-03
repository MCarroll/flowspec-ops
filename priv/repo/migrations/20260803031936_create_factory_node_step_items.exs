defmodule FlowspecOps.Repo.Migrations.CreateFactoryNodeStepItems do
  use Ecto.Migration

  def change do
    create table(:factory_node_step_items) do
      add :factory_node_step_id, references(:factory_node_steps, on_delete: :delete_all), null: false
      add :kind, :string, null: false, default: "equipment"
      add :name, :string, null: false
      add :qty, :integer, null: false, default: 1
      add :unit_cost_cents, :integer
      add :position, :integer, null: false, default: 1
      add :note, :string

      timestamps()
    end

    create index(:factory_node_step_items, [:factory_node_step_id])
  end
end
