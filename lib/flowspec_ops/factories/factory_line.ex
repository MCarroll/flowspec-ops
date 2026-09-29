defmodule FlowspecOps.Factories.FactoryLine do
  use Ecto.Schema
  import Ecto.Changeset

  schema "factory_lines" do
    field :name, :string
    field :position, :integer
    field :target_qty, :integer
    field :window_days, :integer

    belongs_to :factory, FlowspecOps.Factories.Factory
    has_many :nodes, FlowspecOps.Factories.FactoryNode,
      foreign_key: :line_id,
      preload_order: [asc: :position]

    timestamps()
  end

  def changeset(line, attrs) do
    line
    |> cast(attrs, [:factory_id, :name, :position, :target_qty, :window_days])
    |> validate_required([:factory_id, :name, :position])
    |> unique_constraint([:factory_id, :position])
  end
end
