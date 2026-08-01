defmodule FlowspecOps.Repo.Migrations.Wave1FactorySchema do
  use Ecto.Migration

  def change do
    # 1. factory_lines
    create table(:factory_lines) do
      add :factory_id, references(:factories, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :position, :integer, null: false

      timestamps()
    end

    create index(:factory_lines, [:factory_id])
    create unique_index(:factory_lines, [:factory_id, :position])

    # 2. skus (part/SKU reference for routing)
    create table(:skus) do
      add :factory_id, references(:factories, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :code, :string, null: false

      timestamps()
    end

    create index(:skus, [:factory_id])
    create unique_index(:skus, [:factory_id, :code])

    # 3. Alter factory_nodes: drop old station|buffer type, add Wave 1 fields
    alter table(:factory_nodes) do
      remove :type, :string
      add :kind, :string, null: false, default: "work_cell"
      add :queue_role, :string
      add :slots, :integer
      add :inspection_point, :boolean, default: false
      add :line_id, references(:factory_lines, on_delete: :nilify_all)
      add :location_note, :string
      # Supplier timing
      add :lead_time_days, :integer
      add :supply_cadence, :string
      # Transport
      add :transport_duration_minutes, :integer
      add :from_location, :string
      add :to_location, :string
    end

    # 4. factory_links (flow edges between nodes)
    create table(:factory_links) do
      add :factory_id, references(:factories, on_delete: :delete_all), null: false
      add :from_node_id, references(:factory_nodes, on_delete: :delete_all), null: false
      add :to_node_id, references(:factory_nodes, on_delete: :delete_all), null: false
      add :label, :string
      add :sku_filter, :string

      timestamps()
    end

    create index(:factory_links, [:factory_id])
    create index(:factory_links, [:from_node_id])
    create index(:factory_links, [:to_node_id])
  end
end
