defmodule FlowspecOps.Factories.FactorySku do
  use Ecto.Schema
  import Ecto.Changeset

  schema "skus" do
    field :name, :string
    field :code, :string

    belongs_to :factory, FlowspecOps.Factories.Factory

    timestamps()
  end

  def changeset(sku, attrs) do
    sku
    |> cast(attrs, [:factory_id, :name, :code])
    |> validate_required([:factory_id, :name, :code])
    |> unique_constraint([:factory_id, :code])
  end
end
