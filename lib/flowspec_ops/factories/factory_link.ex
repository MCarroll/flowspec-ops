defmodule FlowspecOps.Factories.FactoryLink do
  use Ecto.Schema
  import Ecto.Changeset

  schema "factory_links" do
    field :label, :string
    # Comma-separated SKU codes for routing (e.g. "SKU-A,SKU-B")
    field :sku_filter, :string

    belongs_to :factory, FlowspecOps.Factories.Factory
    belongs_to :from_node, FlowspecOps.Factories.FactoryNode
    belongs_to :to_node, FlowspecOps.Factories.FactoryNode

    timestamps()
  end

  def changeset(link, attrs) do
    link
    |> cast(attrs, [:factory_id, :from_node_id, :to_node_id, :label, :sku_filter])
    |> validate_required([:factory_id, :from_node_id, :to_node_id])
  end
end
