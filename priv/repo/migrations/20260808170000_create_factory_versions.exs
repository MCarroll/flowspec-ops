defmodule FlowspecOps.Repo.Migrations.CreateFactoryVersions do
  use Ecto.Migration

  def change do
    create table(:factory_versions) do
      add :factory_id, references(:factories, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :note, :text
      add :kind, :string, null: false, default: "milestone"
      add :created_by, :string, null: false, default: "michael"
      # Factory header freeze
      add :factory_name, :string, null: false
      add :factory_slug, :string, null: false
      add :client_id, :bigint, null: false
      add :target_qty, :integer
      add :window_days, :integer

      timestamps(updated_at: false)
    end

    create index(:factory_versions, [:factory_id])
    create index(:factory_versions, [:factory_id, :inserted_at])

    create table(:factory_change_log) do
      add :factory_id, references(:factories, on_delete: :delete_all), null: false
      add :actor, :string, null: false, default: "michael"
      add :summary, :string, null: false
      add :entity_type, :string
      add :entity_id, :bigint
      add :factory_version_id, references(:factory_versions, on_delete: :nilify_all)

      timestamps(updated_at: false)
    end

    create index(:factory_change_log, [:factory_id])

    create table(:factory_version_lines) do
      add :version_id, references(:factory_versions, on_delete: :delete_all), null: false
      add :source_id, :bigint, null: false
      add :factory_id, :bigint, null: false
      add :name, :string, null: false
      add :position, :integer, null: false
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:factory_version_lines, [:version_id])

    create table(:factory_version_skus) do
      add :version_id, references(:factory_versions, on_delete: :delete_all), null: false
      add :source_id, :bigint, null: false
      add :factory_id, :bigint, null: false
      add :name, :string, null: false
      add :code, :string, null: false
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:factory_version_skus, [:version_id])

    create table(:factory_version_nodes) do
      add :version_id, references(:factory_versions, on_delete: :delete_all), null: false
      add :source_id, :bigint, null: false
      add :factory_id, :bigint, null: false
      add :line_id, :bigint
      add :kind, :string, null: false
      add :name, :string, null: false
      add :position, :integer, null: false
      add :bypass_allowed, :boolean, null: false, default: false
      add :note, :text
      add :queue_role, :string
      add :slots, :integer
      add :storage_group, :string
      add :crew_size, :integer
      add :inspection_point, :boolean, default: false
      add :gate, :boolean, default: false
      add :product_ready, :boolean, default: false
      add :method_instruction, :boolean, default: false
      add :location_note, :string
      add :lead_time_days, :integer
      add :supply_cadence, :string
      add :setup_days, :integer
      add :first_batch_days, :integer
      add :first_batch_qty, :integer
      add :production_batch_slots, :integer
      add :transport_duration_minutes, :integer
      add :from_location, :string
      add :to_location, :string
      add :vendor_name, :string
      add :batch_size, :integer
      add :ship_weekday, :string
      add :transit_days, :integer
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:factory_version_nodes, [:version_id])

    create table(:factory_version_links) do
      add :version_id, references(:factory_versions, on_delete: :delete_all), null: false
      add :source_id, :bigint, null: false
      add :factory_id, :bigint, null: false
      add :from_node_id, :bigint, null: false
      add :to_node_id, :bigint, null: false
      add :label, :string
      add :sku_filter, :string
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:factory_version_links, [:version_id])

    create table(:factory_version_node_steps) do
      add :version_id, references(:factory_versions, on_delete: :delete_all), null: false
      add :source_id, :bigint, null: false
      add :factory_node_id, :bigint, null: false
      add :name, :string, null: false
      add :position, :integer, null: false
      add :estimated_minutes, :integer
      add :minutes_each, :integer
      add :qty_per_unit, :integer
      add :people, :integer
      add :specs, :string
      add :shared, :boolean, default: true
      add :parallel_with_step_id, :bigint
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:factory_version_node_steps, [:version_id])

    create table(:factory_version_node_step_items) do
      add :version_id, references(:factory_versions, on_delete: :delete_all), null: false
      add :source_id, :bigint, null: false
      add :factory_node_step_id, :bigint, null: false
      add :kind, :string, null: false
      add :name, :string, null: false
      add :qty, :float, null: false, default: 1.0
      add :unit_cost_cents, :integer
      add :pack_qty, :float
      add :position, :integer, null: false, default: 1
      add :note, :string
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end

    create index(:factory_version_node_step_items, [:version_id])
  end
end
