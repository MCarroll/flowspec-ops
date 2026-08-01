defmodule FlowspecOps.Sales.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @status_values [:not_started, :in_progress, :blocked, :done]
  @block_category_values [:awaiting_handoff_internal, :awaiting_handoff_external, :awaiting_research]

  schema "tasks" do
    field :title, :string
    field :commentary, :string
    field :next_action, :string
    field :due_on, :date
    field :status, Ecto.Enum, values: @status_values
    field :block_category, Ecto.Enum, values: @block_category_values
    field :block_detail, :string
    field :blocked_since, :utc_datetime
    field :estimated_minutes, :integer
    field :remaining_estimate_minutes, :integer
    field :priority, :integer

    belongs_to :client, FlowspecOps.Sales.Client
    belongs_to :contact, FlowspecOps.Sales.Contact
    has_many :time_entries, FlowspecOps.Sales.TimeEntry

    timestamps()
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :client_id,
      :contact_id,
      :title,
      :commentary,
      :next_action,
      :due_on,
      :status,
      :block_category,
      :block_detail,
      :blocked_since,
      :estimated_minutes,
      :remaining_estimate_minutes,
      :priority
    ])
    |> validate_required([:client_id, :title, :status, :priority])
    |> unique_constraint(:priority)
  end
end
