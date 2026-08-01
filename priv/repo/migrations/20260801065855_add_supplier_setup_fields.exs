defmodule FlowspecOps.Repo.Migrations.AddSupplierSetupFields do
  use Ecto.Migration

  def change do
    alter table(:factory_nodes) do
      # Supplier setup section
      add :setup_days, :integer
      add :first_batch_days, :integer
      add :first_batch_qty, :integer
      add :production_batch_slots, :integer
    end
  end
end
