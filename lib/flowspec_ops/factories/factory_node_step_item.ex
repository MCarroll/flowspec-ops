defmodule FlowspecOps.Factories.FactoryNodeStepItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "factory_node_step_items" do
    field :kind, Ecto.Enum, values: [:equipment, :material], default: :equipment
    field :name, :string
    # equipment: count of assets; material: burn qty per deliverable unit (frame)
    field :qty, :float, default: 1.0
    # equipment: cost per asset; material: cost per pack/box (purchase unit)
    field :unit_cost_cents, :integer
    # material: pieces per pack/box (e.g. 1500 screws). nil => unit_cost is already per piece
    field :pack_qty, :float
    field :position, :integer, default: 1
    field :note, :string

    belongs_to :step, FlowspecOps.Factories.FactoryNodeStep,
      foreign_key: :factory_node_step_id

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :factory_node_step_id,
      :kind,
      :name,
      :qty,
      :unit_cost_cents,
      :pack_qty,
      :position,
      :note
    ])
    |> validate_required([:factory_node_step_id, :kind, :name, :qty, :position])
    |> validate_number(:qty, greater_than: 0)
    |> validate_number(:pack_qty, greater_than: 0)
    |> validate_number(:unit_cost_cents, greater_than_or_equal_to: 0)
  end

  # Stand-up asset: qty × unit cost
  def stand_up_cents(%__MODULE__{kind: :equipment, qty: qty, unit_cost_cents: cost})
      when is_number(qty) and is_integer(cost),
      do: round(qty * cost)

  def stand_up_cents(_), do: nil

  # Burn per deliverable: qty pieces/frame × (pack_price / pack_qty)
  def burn_per_unit_cents(%__MODULE__{kind: :material, qty: qty, unit_cost_cents: pack_cost, pack_qty: pack_qty})
      when is_number(qty) and is_integer(pack_cost) and is_number(pack_qty) and pack_qty > 0 do
    round(qty * pack_cost / pack_qty)
  end

  def burn_per_unit_cents(%__MODULE__{kind: :material, qty: qty, unit_cost_cents: piece_cost, pack_qty: nil})
      when is_number(qty) and is_integer(piece_cost),
      do: round(qty * piece_cost)

  def burn_per_unit_cents(_), do: nil

  def line_total_cents(%__MODULE__{kind: :equipment} = item), do: stand_up_cents(item)
  def line_total_cents(%__MODULE__{kind: :material} = item), do: burn_per_unit_cents(item)
  def line_total_cents(_), do: nil
end
