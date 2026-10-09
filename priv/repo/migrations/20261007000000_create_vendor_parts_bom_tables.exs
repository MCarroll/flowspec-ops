defmodule FlowspecOps.Repo.Migrations.CreateVendorPartsBomTables do
  use Ecto.Migration

  def change do
    create table(:vendors) do
      add :name, :string, null: false
      add :contact_name, :string
      add :contact_email, :string
      add :contact_phone, :string
      add :capabilities, :string
      add :note, :string

      timestamps()
    end

    create unique_index(:vendors, [:name])

    create table(:parts) do
      add :name, :string, null: false
      add :part_number, :string
      add :kind, :string, null: false
      add :description, :string
      add :unit_cost_cents, :integer
      add :unit_of_measure, :string
      add :vendor_id, references(:vendors, on_delete: :nilify_all)

      timestamps()
    end

    create index(:parts, [:vendor_id])
    create index(:parts, [:kind])

    create table(:projects) do
      add :name, :string, null: false
      add :description, :string
      add :config, :map
      add :client_id, references(:clients, on_delete: :delete_all), null: false
      add :factory_id, references(:factories, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:projects, [:client_id])
    create index(:projects, [:factory_id])

    create table(:boms) do
      add :design_name, :string, null: false
      add :version, :string, null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:boms, [:project_id, :design_name, :version])
    create index(:boms, [:project_id])

    create table(:bom_items) do
      add :qty, :float, null: false
      add :position, :integer, null: false
      add :bom_id, references(:boms, on_delete: :delete_all), null: false
      add :part_id, references(:parts, on_delete: :delete_all), null: false
      add :parent_id, references(:bom_items, on_delete: :delete_all)
      add :manufactured_by_id, references(:vendors, on_delete: :nilify_all)
      add :installed_by_id, references(:vendors, on_delete: :nilify_all)

      timestamps()
    end

    create index(:bom_items, [:bom_id])
    create index(:bom_items, [:part_id])
    create index(:bom_items, [:parent_id])
    create index(:bom_items, [:manufactured_by_id])
    create index(:bom_items, [:installed_by_id])
  end
end
