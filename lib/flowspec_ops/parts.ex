defmodule FlowspecOps.Parts do
  import Ecto.Query
  alias FlowspecOps.Repo
  alias FlowspecOps.Parts.Part

  def list_parts do
    Repo.all(from p in Part, order_by: p.name, preload: :vendor)
  end

  def get_part!(id), do: Repo.get!(Part, id) |> Repo.preload(:vendor)

  def create_part(attrs) do
    %Part{}
    |> Part.changeset(attrs)
    |> Repo.insert()
  end

  def update_part(%Part{} = part, attrs) do
    part
    |> Part.changeset(attrs)
    |> Repo.update()
  end

  def delete_part(%Part{} = part), do: Repo.delete(part)
end
