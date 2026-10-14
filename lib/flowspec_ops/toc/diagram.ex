defmodule FlowspecOps.TOC.Diagram do
  use Ecto.Schema
  import Ecto.Changeset

  schema "toc_diagrams" do
    field :name, :string
    field :dsl, :string
    # "tree" (CRT) or "cloud" (CRD surface) — the two kinds, never mixed
    field :kind, :string, default: "tree"
    has_many :versions, FlowspecOps.TOC.CloudVersion

    timestamps()
  end

  def changeset(diagram, attrs) do
    diagram
    |> cast(attrs, [:name, :dsl, :kind])
    |> validate_required([:name])
    |> validate_inclusion(:kind, ["tree", "cloud"])
  end
end
