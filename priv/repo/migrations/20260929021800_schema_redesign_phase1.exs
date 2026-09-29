defmodule FlowspecOps.Repo.Migrations.SchemaRedesignPhase1 do
  use Ecto.Migration

  def change do
    # 1. factories: add location, remove target_qty/window_days
    alter table(:factories) do
      add :location, :string
    end

    execute "ALTER TABLE factories DROP COLUMN IF EXISTS target_qty"
    execute "ALTER TABLE factories DROP COLUMN IF EXISTS window_days"

    # 2. factory_lines: add target_qty, window_days
    alter table(:factory_lines) do
      add :target_qty, :integer
      add :window_days, :integer
    end

    # 3. factory_nodes: add location, operational, work_cell fields, movement fields, transport_mode
    alter table(:factory_nodes) do
      add :location, :string
      add :operational, :boolean, default: false, null: false

      # work_cell embedded buffers (crew_size already exists from prior migration)
      add :input_slots, :integer
      add :output_slots, :integer

      # work_cell power/data specs
      add :voltage, :string
      add :amperage, :string
      add :phase, :string
      add :port_count, :integer
      add :media_type, :string
      add :power_note, :text
      add :data_note, :text

      # movement card fields (slots, from_location, to_location already exist)
      add :qty_in_circulation, :integer
      add :trips_per_day, :integer
      add :duration_minutes, :integer
      add :operator_count, :integer

      # transport mode
      add :transport_mode, :string
    end

    # 4. equipment table
    create table(:equipment) do
      add :factory_node_step_id, references(:factory_node_steps, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :serial, :string
      add :status, :string, null: false, default: "spec'd"
      add :power_circuit, :string
      add :data_port, :string
      add :note, :text

      timestamps()
    end

    create index(:equipment, [:factory_node_step_id])

    # 5. build_out_items table
    create table(:build_out_items) do
      add :card_id, references(:factory_nodes, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :cost_cents, :integer, null: false
      add :category, :string, null: false
      add :date, :date
      add :note, :text

      timestamps()
    end

    create index(:build_out_items, [:card_id])
  end
end
