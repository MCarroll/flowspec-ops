defmodule FlowspecOps.Repo.Migrations.AddGateToFactoryNodes do
  use Ecto.Migration

  def change do
    alter table(:factory_nodes) do
      add :gate, :boolean, null: false, default: false
    end
  end
end
