defmodule FlowspecOps.Repo.Migrations.AddLocationToFactoryLines do
  use Ecto.Migration

  def change do
    alter table(:factory_lines) do
      add :location, :string
    end
  end
end
