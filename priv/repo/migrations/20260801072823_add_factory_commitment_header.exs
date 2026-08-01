defmodule FlowspecOps.Repo.Migrations.AddFactoryCommitmentHeader do
  use Ecto.Migration

  def change do
    alter table(:factories) do
      add :target_qty, :integer
      add :window_days, :integer
    end
  end
end
