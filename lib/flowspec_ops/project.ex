defmodule FlowspecOps.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    field :description, :string
    field :config, :map

    belongs_to :client, FlowspecOps.Sales.Client
    belongs_to :factory, FlowspecOps.Factories.Factory
    has_many :boms, FlowspecOps.BOMs.BOM

    timestamps()
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description, :config, :client_id, :factory_id])
    |> validate_required([:name, :client_id, :factory_id])
  end
end
