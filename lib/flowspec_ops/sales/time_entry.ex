defmodule FlowspecOps.Sales.TimeEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "time_entries" do
    field :started_at, :utc_datetime
    field :ended_at, :utc_datetime
    field :note, :string
    field :billable, :boolean, default: false

    belongs_to :task, FlowspecOps.Sales.Task

    timestamps()
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:task_id, :started_at, :ended_at, :note, :billable])
    |> validate_required([:task_id, :started_at, :ended_at])
  end
end
