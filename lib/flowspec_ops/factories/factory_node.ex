defmodule FlowspecOps.Factories.FactoryNode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "factory_nodes" do
    field :kind, Ecto.Enum, values: [:work_cell, :queue, :supplier, :transport]
    field :name, :string
    field :position, :integer
    field :bypass_allowed, :boolean, default: false
    field :note, :string
    # Queue-specific
    field :queue_role, Ecto.Enum, values: [:queue, :storage_lot, :feeding_buffer]
    field :slots, :integer
    field :storage_group, :string
    field :crew_size, :integer
    # Shared
    field :inspection_point, :boolean, default: false
    field :gate, :boolean, default: false
    field :product_ready, :boolean, default: false
    field :method_instruction, :boolean, default: false
    field :location_note, :string
    # Supplier timing / setup
    field :lead_time_days, :integer
    field :supply_cadence, :string
    field :setup_days, :integer
    field :first_batch_days, :integer
    field :first_batch_qty, :integer
    field :production_batch_slots, :integer
    # Transport
    field :transport_duration_minutes, :integer
    field :from_location, :string
    field :to_location, :string
    field :vendor_name, :string
    field :batch_size, :integer
    field :ship_weekday, :string
    field :transit_days, :integer

    belongs_to :factory, FlowspecOps.Factories.Factory
    belongs_to :line, FlowspecOps.Factories.FactoryLine
    has_many :steps, FlowspecOps.Factories.FactoryNodeStep,
      foreign_key: :factory_node_id,
      preload_order: [asc: :position]

    timestamps()
  end

  def changeset(node, attrs) do
    node
    |> cast(attrs, [
      :factory_id, :kind, :name, :position, :bypass_allowed, :note,
      :queue_role, :slots, :storage_group, :crew_size, :inspection_point, :gate, :product_ready, :method_instruction, :line_id, :location_note,
      :lead_time_days, :supply_cadence,
      :setup_days, :first_batch_days, :first_batch_qty, :production_batch_slots,
      :transport_duration_minutes, :from_location, :to_location,
      :vendor_name, :batch_size, :ship_weekday, :transit_days
    ])
    |> validate_required([:factory_id, :kind, :name, :position])
    |> unique_constraint([:factory_id, :line_id, :position], name: :factory_nodes_factory_id_line_id_position_index)
  end
end
