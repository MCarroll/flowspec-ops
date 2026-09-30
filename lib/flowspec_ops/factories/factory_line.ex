defmodule FlowspecOps.Factories.FactoryLine do
  use Ecto.Schema
  import Ecto.Changeset

  schema "factory_lines" do
    field :name, :string
    field :position, :integer

    belongs_to :factory, FlowspecOps.Factories.Factory
    belongs_to :master_production_line, FlowspecOps.Factories.MasterProductionLine,
      foreign_key: :master_production_line_id
    has_many :nodes, FlowspecOps.Factories.FactoryNode,
      foreign_key: :line_id,
      preload_order: [asc: :position]

    timestamps()
  end

  def changeset(line, attrs) do
    line
    |> cast(attrs, [:factory_id, :name, :position, :master_production_line_id])
    |> validate_required([:factory_id, :name, :position])
    |> unique_constraint([:factory_id, :position])
  end
end
