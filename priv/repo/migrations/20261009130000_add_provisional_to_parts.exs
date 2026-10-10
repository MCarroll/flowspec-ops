defmodule FlowspecOps.Repo.Migrations.AddProvisionalToParts do
  use Ecto.Migration

  def change do
    alter table(:parts) do
      add :provisional, :boolean, default: false, null: false
    end
  end
end
