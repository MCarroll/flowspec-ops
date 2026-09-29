defmodule FlowspecOps.Factories.Equipment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "equipment" do
    field :name, :string
    field :serial, :string
    field :status, Ecto.Enum, values: [:"spec'd", :ordered, :delivered, :installed]
    field :power_circuit, :string
    field :data_port, :string
    field :note, :string

    belongs_to :step, FlowspecOps.Factories.FactoryNodeStep,
      foreign_key: :factory_node_step_id

    timestamps()
  end

  def changeset(equipment, attrs) do
    equipment
    |> cast(attrs, [
      :factory_node_step_id, :name, :serial, :status,
      :power_circuit, :data_port, :note
    ])
    |> validate_required([:factory_node_step_id, :name, :status])
  end
end
