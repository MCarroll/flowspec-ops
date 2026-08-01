defmodule FlowspecOps.Sales.Client do
  use Ecto.Schema
  import Ecto.Changeset

  @stage_values [:prospect, :proposal, :engaged, :closed_won, :closed_lost]

  schema "clients" do
    field :name, :string
    field :short_name, :string
    field :slug, :string
    field :stage, Ecto.Enum, values: @stage_values
    field :source, :string
    field :aka, :string

    has_many :contacts, FlowspecOps.Sales.Contact
    has_many :offers, FlowspecOps.Sales.Offer
    has_many :tasks, FlowspecOps.Sales.Task
    has_many :activity_log_entries, FlowspecOps.Sales.ActivityLogEntry

    timestamps()
  end

  def changeset(client, attrs) do
    client
    |> cast(attrs, [:name, :short_name, :slug, :stage, :source, :aka])
    |> validate_required([:name, :short_name, :slug, :stage])
    |> unique_constraint(:slug)
  end
end
