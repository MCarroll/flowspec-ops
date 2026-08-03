defmodule FlowspecOps.Factories.FactoryNodeStep do
  use Ecto.Schema
  import Ecto.Changeset

  schema "factory_node_steps" do
    field :name, :string
    field :position, :integer
    field :estimated_minutes, :integer
    field :minutes_each, :integer
    field :qty_per_unit, :integer
    field :people, :integer
    field :specs, :string

    belongs_to :factory_node, FlowspecOps.Factories.FactoryNode

    belongs_to :parallel_with_step, __MODULE__,
      foreign_key: :parallel_with_step_id

    has_many :items, FlowspecOps.Factories.FactoryNodeStepItem,
      foreign_key: :factory_node_step_id,
      preload_order: [asc: :position]

    timestamps()
  end

  def changeset(step, attrs) do
    step
    |> cast(attrs, [
      :factory_node_id,
      :name,
      :position,
      :estimated_minutes,
      :minutes_each,
      :qty_per_unit,
      :people,
      :specs,
      :parallel_with_step_id
    ])
    |> validate_required([:factory_node_id, :name, :position])
    |> validate_number(:people, greater_than: 0)
    |> validate_number(:qty_per_unit, greater_than: 0)
    |> validate_number(:minutes_each, greater_than: 0)
    |> unique_constraint([:factory_node_id, :position])
    |> foreign_key_constraint(:parallel_with_step_id)
  end
end
