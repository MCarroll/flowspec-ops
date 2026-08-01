defmodule FlowspecOps.Factories.FactoryNodeStep do
  use Ecto.Schema
  import Ecto.Changeset

  schema "factory_node_steps" do
    field :name, :string
    field :position, :integer
    field :estimated_minutes, :integer

    belongs_to :factory_node, FlowspecOps.Factories.FactoryNode

    timestamps()
  end

  def changeset(step, attrs) do
    step
    |> cast(attrs, [:factory_node_id, :name, :position, :estimated_minutes])
    |> validate_required([:factory_node_id, :name, :position])
    |> unique_constraint([:factory_node_id, :position])
  end
end
