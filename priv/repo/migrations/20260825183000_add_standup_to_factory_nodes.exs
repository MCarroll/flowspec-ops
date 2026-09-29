defmodule FlowspecOps.Repo.Migrations.AddStandupToFactoryNodes do
  use Ecto.Migration

  def change do
    alter table(:factory_nodes) do
      add :standup_weeks, :float
      add :standup_people, :integer
      add :standup_source, :string
      add :standup_note, :string
    end

    alter table(:factory_version_nodes) do
      add :standup_weeks, :float
      add :standup_people, :integer
      add :standup_source, :string
      add :standup_note, :string
    end
  end
end
