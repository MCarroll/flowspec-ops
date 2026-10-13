defmodule FlowspecOps.TOC.Diagram do
  use Ecto.Schema
  import Ecto.Changeset

  schema "toc_diagrams" do
    field :name, :string
    field :dsl, :string
    field :graph_json, :map, default: %{}

    timestamps()
  end

  def changeset(diagram, attrs) do
    diagram
    |> cast(attrs, [:name, :dsl, :graph_json])
    |> validate_required([:name])
  end
end
