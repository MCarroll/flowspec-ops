defmodule FlowspecOps.Repo.Migrations.AddCommitmentToVersionLines do
  use Ecto.Migration

  def change do
    alter table(:factory_version_lines) do
      add :target_qty, :integer
      add :window_days, :integer
    end
  end
end
