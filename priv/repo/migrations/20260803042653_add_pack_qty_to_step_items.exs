defmodule FlowspecOps.Repo.Migrations.AddPackQtyToStepItems do
  use Ecto.Migration

  def change do
    alter table(:factory_node_step_items) do
      add :pack_qty, :integer
    end
  end
end
