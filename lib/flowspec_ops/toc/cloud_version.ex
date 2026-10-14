defmodule FlowspecOps.TOC.CloudVersion do
  @moduledoc """
  A versioned snapshot of a cloud's DSL. A CRT pins one version; swapping
  the pin to a newer version replaces the embedded cloud. Cloud DSL is the
  storage format — versions are copies, never live references.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "cloud_versions" do
    field :version, :integer
    field :dsl, :string
    field :note, :string
    belongs_to :cloud, FlowspecOps.TOC.Diagram
    timestamps()
  end

  def changeset(version, attrs) do
    version
    |> cast(attrs, [:cloud_id, :version, :dsl, :note])
    |> validate_required([:cloud_id, :version])
  end
end
