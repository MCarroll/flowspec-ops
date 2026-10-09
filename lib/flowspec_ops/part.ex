defmodule FlowspecOps.Parts.Part do
  use Ecto.Schema
  import Ecto.Changeset

  schema "parts" do
    field :name, :string
    field :part_number, :string
    field :kind, Ecto.Enum, values: [:raw_material, :component, :sub_assembly, :assembly]
    field :description, :string
    field :unit_cost_cents, :integer
    field :unit_of_measure, :string
    field :fake, :boolean, default: false
    field :specs, :map, default: %{}

    belongs_to :vendor, FlowspecOps.Vendors.Vendor
    has_many :bom_items, FlowspecOps.BOMs.BOMItem

    timestamps()
  end

  def changeset(part, attrs) do
    part
    |> cast(attrs, [:name, :part_number, :kind, :description, :unit_cost_cents, :unit_of_measure, :vendor_id, :fake, :specs])
    |> validate_required([:name, :kind])
    |> validate_number(:unit_cost_cents, greater_than_or_equal_to: 0)
  end
end
