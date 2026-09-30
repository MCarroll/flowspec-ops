defmodule FlowspecOps.Repo.Migrations.AddCommitmentToVersionLines do
  use Ecto.Migration

  def change do
    alter table(:factory_version_lines) do
      add :master_production_line_id, :bigint
    end
  end
end
