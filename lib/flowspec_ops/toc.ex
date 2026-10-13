defmodule FlowspecOps.TOC do
  import Ecto.Query
  alias FlowspecOps.Repo
  alias FlowspecOps.TOC.Diagram

  def list_diagrams do
    Repo.all(from d in Diagram, order_by: d.name)
  end

  def get_diagram!(id), do: Repo.get!(Diagram, id)

  def create_diagram(attrs) do
    %Diagram{}
    |> Diagram.changeset(attrs)
    |> Repo.insert()
  end

  def update_diagram(%Diagram{} = diagram, attrs) do
    diagram
    |> Diagram.changeset(attrs)
    |> Repo.update()
  end

  def delete_diagram(%Diagram{} = diagram), do: Repo.delete(diagram)
end
