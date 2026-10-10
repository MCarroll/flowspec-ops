defmodule FlowspecOps.Factories.FactoryNodeStep do
  use Ecto.Schema
  import Ecto.Changeset

  schema "factory_node_steps" do
    field :name, :string
    field :position, :integer
    field :estimated_minutes, :integer
    field :duration_days, :integer
    field :minutes_each, :integer
    field :qty_per_unit, :integer
    field :people, :integer
    field :specs, :string
    field :shared, :boolean, default: true

    belongs_to :factory_node, FlowspecOps.Factories.FactoryNode

    belongs_to :parallel_with_step, __MODULE__,
      foreign_key: :parallel_with_step_id

    has_many :items, FlowspecOps.Factories.FactoryNodeStepItem,
      foreign_key: :factory_node_step_id,
      preload_order: [asc: :position]

    timestamps()
  end

  def changeset(step, attrs) do
    step
    |> cast(attrs, [
      :factory_node_id,
      :name,
      :position,
      :estimated_minutes,
      :duration_days,
      :minutes_each,
      :qty_per_unit,
      :people,
      :specs,
      :shared,
      :parallel_with_step_id
    ])
    |> validate_required([:factory_node_id, :name, :position])
    |> validate_number(:people, greater_than: 0)
    |> validate_number(:qty_per_unit, greater_than: 0)
    |> validate_number(:minutes_each, greater_than: 0)
    |> unique_constraint([:factory_node_id, :position])
    |> foreign_key_constraint(:parallel_with_step_id)
  end

  # --- Timing helpers ---

  # Work content: qty × min/ea, or estimated_minutes when no qty/each.
  def content_minutes(%__MODULE__{qty_per_unit: qty, minutes_each: each})
      when is_integer(qty) and is_integer(each),
      do: qty * each

  def content_minutes(%__MODULE__{estimated_minutes: est}) when is_integer(est), do: est
  def content_minutes(_), do: nil

  # Process time: ceil(content / people) when shared (default), else content.
  # shared = nil treated as true (safe pre-migration default).
  def process_minutes(%__MODULE__{} = step) do
    case content_minutes(step) do
      nil ->
        nil

      content ->
        if step.shared != false and is_integer(step.people) and step.people > 0 do
          ceil(content / step.people)
        else
          content
        end
    end
  end
end
