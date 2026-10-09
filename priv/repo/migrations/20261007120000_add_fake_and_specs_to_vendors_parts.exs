defmodule FlowspecOps.Repo.Migrations.AddFakeAndSpecsToVendorsParts do
  use Ecto.Migration

  def change do
    alter table(:vendors) do
      add :fake, :boolean, default: false, null: false
    end

    alter table(:parts) do
      add :fake, :boolean, default: false, null: false
      add :specs, :map, default: %{}
    end
  end
end
