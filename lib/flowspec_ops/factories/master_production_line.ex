defmodule FlowspecOps.Factories.MasterProductionLine do
  use Ecto.Schema
  import Ecto.Changeset

  schema "master_production_lines" do
    field :name, :string
    field :description, :string
    field :target_qty, :integer
    field :window_days, :integer
    field :start_date, :date

    belongs_to :factory, FlowspecOps.Factories.Factory
    has_many :lines, FlowspecOps.Factories.FactoryLine,
      foreign_key: :master_production_line_id

    timestamps()
  end

  def changeset(mpl, attrs) do
    mpl
    |> cast(attrs, [:factory_id, :name, :description, :target_qty, :window_days, :start_date])
    |> validate_required([:factory_id, :name])
    |> validate_number(:target_qty, greater_than: 0)
    |> validate_number(:window_days, greater_than: 0)
  end
end
