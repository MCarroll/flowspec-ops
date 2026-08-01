defmodule FlowspecOps.Sales.ActivityLogEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @kind_values [:work, :comms]

  schema "activity_log_entries" do
    field :kind, Ecto.Enum, values: @kind_values
    field :author, :string
    field :body, :string
    field :occurred_at, :utc_datetime

    belongs_to :client, FlowspecOps.Sales.Client
    belongs_to :contact, FlowspecOps.Sales.Contact

    timestamps(updated_at: false)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:client_id, :contact_id, :kind, :author, :body, :occurred_at])
    |> validate_required([:client_id, :kind, :author, :body, :occurred_at])
  end
end
