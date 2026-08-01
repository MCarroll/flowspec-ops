defmodule FlowspecOps.Sales.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    field :name, :string
    field :role, :string
    field :email, :string
    field :phone, :string

    belongs_to :client, FlowspecOps.Sales.Client

    timestamps()
  end

  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:client_id, :name, :role, :email, :phone])
    |> validate_required([:client_id, :name, :role])
  end
end
