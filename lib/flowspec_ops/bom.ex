defmodule FlowspecOps.BOMs.BOM do
  use Ecto.Schema
  import Ecto.Changeset

  schema "boms" do
    field :design_name, :string
    field :version, :string

    belongs_to :project, FlowspecOps.Projects.Project
    has_many :items, FlowspecOps.BOMs.BOMItem

    timestamps()
  end

  def changeset(bom, attrs) do
    bom
    |> cast(attrs, [:design_name, :version, :project_id])
    |> validate_required([:design_name, :version, :project_id])
    |> unique_constraint([:project_id, :design_name, :version], name: :boms_project_id_design_name_version_index)
  end
end
