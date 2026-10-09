defmodule FlowspecOps.Repo.Migrations.AddVendorAndPartToFactoryNodes do
  use Ecto.Migration

  def change do
    alter table(:factory_nodes) do
      add :vendor_id, references(:vendors, on_delete: :nilify_all)
      add :part_id, references(:parts, on_delete: :nilify_all)
    end

    create index(:factory_nodes, [:vendor_id])
    create index(:factory_nodes, [:part_id])
  end
end
