defmodule FlowspecOps.Vendors.Vendor do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vendors" do
    field :name, :string
    field :contact_name, :string
    field :contact_email, :string
    field :contact_phone, :string
    field :capabilities, :string
    field :note, :string
    field :fake, :boolean, default: false

    has_many :parts, FlowspecOps.Parts.Part
    has_many :manufactured_boms, FlowspecOps.BOMs.BOMItem, foreign_key: :manufactured_by_id
    has_many :installed_boms, FlowspecOps.BOMs.BOMItem, foreign_key: :installed_by_id

    timestamps()
  end

  def changeset(vendor, attrs) do
    vendor
    |> cast(attrs, [:name, :contact_name, :contact_email, :contact_phone, :capabilities, :note, :fake])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
