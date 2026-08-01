defmodule FlowspecOps.Repo.Migrations.AddTransportScheduleFields do
  use Ecto.Migration

  def change do
    alter table(:factory_nodes) do
      add :vendor_name, :string
      add :batch_size, :integer
      add :ship_weekday, :string
      add :transit_days, :integer
    end
  end
end
