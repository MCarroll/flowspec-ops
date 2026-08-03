defmodule FlowspecOps.Repo.Migrations.StepParallelAndDecimalQty do
  use Ecto.Migration

  def change do
    alter table(:factory_node_steps) do
      add :parallel_with_step_id, references(:factory_node_steps, on_delete: :nilify_all)
    end

    alter table(:factory_node_step_items) do
      modify :qty, :float, from: :integer
      modify :pack_qty, :float, from: :integer
    end
  end
end
