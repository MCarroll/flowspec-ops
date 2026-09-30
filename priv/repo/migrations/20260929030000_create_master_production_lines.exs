defmodule FlowspecOps.Repo.Migrations.CreateMasterProductionLines do
  use Ecto.Migration

  def change do
    create table(:master_production_lines) do
      add :factory_id, references(:factories, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :string
      add :target_qty, :integer
      add :window_days, :integer
      add :start_date, :date

      timestamps()
    end

    create index(:master_production_lines, [:factory_id])

    alter table(:factory_lines) do
      add :master_production_line_id, references(:master_production_lines, on_delete: :nilify_all)
    end

    execute "ALTER TABLE factory_lines DROP COLUMN IF EXISTS target_qty"
    execute "ALTER TABLE factory_lines DROP COLUMN IF EXISTS window_days"
  end
end
