defmodule FlowspecOps.Factories.MasterProductionLine do
  use Ecto.Schema
  import Ecto.Changeset

  schema "master_production_lines" do
    field :name, :string
    field :description, :string
    field :target_qty, :integer
    field :window_days, :integer
    field :start_date, :date
    field :selling_price, :decimal
    field :monthly_oe, :decimal
    field :operating_seconds_per_day, :integer
    field :operating_days_per_year, :integer
    field :market_variability_factor, :decimal
    field :equipment_capex, :decimal

    belongs_to :factory, FlowspecOps.Factories.Factory
    has_many :lines, FlowspecOps.Factories.FactoryLine,
      foreign_key: :master_production_line_id

    timestamps()
  end

  def changeset(mpl, attrs) do
    mpl
    |> cast(attrs, [:factory_id, :name, :description, :target_qty, :window_days, :start_date, :selling_price, :monthly_oe, :operating_seconds_per_day, :operating_days_per_year, :market_variability_factor, :equipment_capex])
    |> validate_required([:factory_id, :name])
    |> validate_number(:target_qty, greater_than: 0)
    |> validate_number(:window_days, greater_than: 0)
  end
end
