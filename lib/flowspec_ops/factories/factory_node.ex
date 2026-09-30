defmodule FlowspecOps.Factories.FactoryNode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "factory_nodes" do
    field :kind, Ecto.Enum, values: [:work_cell, :queue, :supplier, :transport, :movement]
    field :name, :string
    field :position, :integer
    field :bypass_allowed, :boolean, default: false
    field :note, :string
    field :location, :string
    field :operational, :boolean, default: false

    # Work cell embedded buffers
    field :input_slots, :integer
    field :output_slots, :integer

    # Work cell power/data specs
    field :voltage, :string
    field :amperage, :string
    field :phase, :string
    field :port_count, :integer
    field :media_type, :string
    field :power_note, :string
    field :data_note, :string
    # Queue-specific
    field :queue_role, Ecto.Enum, values: [:queue, :storage_lot, :feeding_buffer]
    field :slots, :integer
    field :storage_group, :string
    field :crew_size, :integer
    # Stand-up demand (engineered full kit — not PM execution)
    field :standup_weeks, :float
    field :standup_people, :integer
    field :standup_source, Ecto.Enum, values: [:in_house, :subcontract, :mixed]
    field :standup_note, :string
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
    field :transport_mode, Ecto.Enum, values: [:external, :internal]

    # Movement card fields
    field :duration_minutes, :integer
    field :qty_in_circulation, :integer
    field :trips_per_day, :integer
    field :operator_count, :integer

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
      :location, :operational,
      :input_slots, :output_slots, :crew_size,
      :voltage, :amperage, :phase, :port_count, :media_type, :power_note, :data_note,
      :queue_role, :slots, :storage_group,
      :standup_weeks, :standup_people, :standup_source, :standup_note,
      :inspection_point, :gate, :product_ready, :method_instruction, :line_id, :location_note,
      :lead_time_days, :supply_cadence,
      :setup_days, :first_batch_days, :first_batch_qty, :production_batch_slots,
      :transport_duration_minutes, :from_location, :to_location,
      :vendor_name, :batch_size, :ship_weekday, :transit_days, :transport_mode,
      :qty_in_circulation, :trips_per_day, :operator_count, :duration_minutes
    ])
    |> validate_number(:standup_weeks, greater_than: 0)
    |> validate_number(:standup_people, greater_than: 0)
    |> validate_required([:factory_id, :kind, :name, :position])
    |> unique_constraint([:factory_id, :line_id, :position], name: :factory_nodes_factory_id_line_id_position_index)
  end
end
