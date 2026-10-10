defmodule FlowspecOps.Repo.Migrations.AddSupplyBatchFrequency do
  use Ecto.Migration

  def change do
    alter table(:factory_nodes) do
      add :supply_batch, :integer
      add :supply_frequency_days, :integer
    end
  end
end
