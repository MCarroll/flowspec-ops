defmodule FlowspecOps.Repo.Migrations.AddSupplyBatchFrequencyToVersionNodes do
  use Ecto.Migration

  def change do
    alter table(:factory_version_nodes) do
      add :supply_batch, :integer
      add :supply_frequency_days, :integer
    end
  end
end
