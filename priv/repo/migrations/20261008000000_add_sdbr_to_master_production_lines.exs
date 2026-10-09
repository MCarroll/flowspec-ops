defmodule FlowspecOps.Repo.Migrations.AddSDBRToMasterProductionLines do
  use Ecto.Migration

  def change do
    alter table(:master_production_lines) do
      add :selling_price, :decimal
      add :monthly_oe, :decimal
      add :operating_seconds_per_day, :integer
      add :operating_days_per_year, :integer
      add :market_variability_factor, :decimal
      add :equipment_capex, :decimal
    end
  end
end
