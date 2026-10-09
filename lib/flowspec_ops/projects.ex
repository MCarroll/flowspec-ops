defmodule FlowspecOps.Projects do
  import Ecto.Query
  alias FlowspecOps.Repo
  alias FlowspecOps.Projects.Project

  def list_projects do
    Repo.all(from p in Project, order_by: p.name, preload: [:client, :factory])
  end

  def get_project!(id) do
    Repo.get!(Project, id)
    |> Repo.preload([:client, :factory, boms: [items: [:part, :manufactured_by, :installed_by]]])
  end

  def create_project(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  def delete_project(%Project{} = project), do: Repo.delete(project)
end
