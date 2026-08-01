defmodule FlowspecOps.Sales.Offer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "offers" do
    field :title, :string
    field :amount_cents, :integer
    field :unit, :string
    field :description, :string

    belongs_to :client, FlowspecOps.Sales.Client

    timestamps()
  end

  def changeset(offer, attrs) do
    offer
    |> cast(attrs, [:client_id, :title, :amount_cents, :unit, :description])
    |> validate_required([:client_id, :title, :amount_cents, :unit])
  end
end
