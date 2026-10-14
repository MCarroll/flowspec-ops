defmodule FlowspecOps.TOC.Injection do
  @moduledoc """
  An injection: a DB-numbered record. The id IS the number. Postulated once
  — from a cloud or a tree — referenced by both. Used in the FRT.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "injections" do
    field :text, :string
    field :note, :string
    timestamps()
  end

  def changeset(injection, attrs) do
    injection
    |> cast(attrs, [:text, :note])
    |> validate_required([:text])
  end
end
