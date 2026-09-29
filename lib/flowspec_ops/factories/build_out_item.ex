defmodule FlowspecOps.Factories.BuildOutItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "build_out_items" do
    field :name, :string
    field :cost_cents, :integer
    field :category, Ecto.Enum, values: [:capex, :opex]
    field :date, :date
    field :note, :string

    belongs_to :card, FlowspecOps.Factories.FactoryNode,
      foreign_key: :card_id

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:card_id, :name, :cost_cents, :category, :date, :note])
    |> validate_required([:card_id, :name, :cost_cents, :category])
    |> validate_number(:cost_cents, greater_than_or_equal_to: 0)
  end
end
