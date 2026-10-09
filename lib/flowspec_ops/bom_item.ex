defmodule FlowspecOps.BOMs.BOMItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bom_items" do
    field :qty, :float
    field :position, :integer

    belongs_to :bom, FlowspecOps.BOMs.BOM
    belongs_to :part, FlowspecOps.Parts.Part
    belongs_to :parent, __MODULE__, foreign_key: :parent_id
    belongs_to :manufactured_by, FlowspecOps.Vendors.Vendor, foreign_key: :manufactured_by_id
    belongs_to :installed_by, FlowspecOps.Vendors.Vendor, foreign_key: :installed_by_id

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:qty, :position, :bom_id, :part_id, :parent_id, :manufactured_by_id, :installed_by_id])
    |> validate_required([:qty, :position, :bom_id, :part_id])
    |> validate_number(:qty, greater_than: 0)
    |> foreign_key_constraint(:parent_id)
  end
end
