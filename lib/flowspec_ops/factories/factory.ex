defmodule FlowspecOps.Factories.Factory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "factories" do
    field :name, :string
    field :slug, :string
    field :target_qty, :integer
    field :window_days, :integer

    belongs_to :client, FlowspecOps.Sales.Client
    has_many :nodes, FlowspecOps.Factories.FactoryNode,
      foreign_key: :factory_id,
      preload_order: [asc: :position]
    has_many :lines, FlowspecOps.Factories.FactoryLine,
      foreign_key: :factory_id,
      preload_order: [asc: :position]
    has_many :links, FlowspecOps.Factories.FactoryLink,
      foreign_key: :factory_id
    has_many :skus, FlowspecOps.Factories.FactorySku,
      foreign_key: :factory_id

    timestamps()
  end

  def changeset(factory, attrs) do
    factory
    |> cast(attrs, [:name, :slug, :client_id, :target_qty, :window_days])
    |> validate_required([:name, :slug, :client_id])
    |> validate_number(:target_qty, greater_than: 0)
    |> validate_number(:window_days, greater_than: 0)
    |> unique_constraint(:slug)
  end
end
