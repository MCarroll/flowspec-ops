defmodule FlowspecOps.TOC do
  @moduledoc """
  Context for TOC diagrams (trees), clouds, cloud versions, and injections.

  Trees and clouds are both `toc_diagrams` rows, separated by `kind`.
  Clouds version through `cloud_versions`; a tree pins one version.
  Injections are DB-numbered records referenced by both.
  """
  import Ecto.Query
  alias FlowspecOps.Repo
  alias FlowspecOps.TOC.Diagram
  alias FlowspecOps.TOC.CloudVersion
  alias FlowspecOps.TOC.Injection

  # ---- diagrams (trees + clouds) ------------------------------------------

  def list_diagrams, do: Repo.all(from d in Diagram, order_by: d.name)
  def list_trees, do: Repo.all(from d in Diagram, where: d.kind == "tree", order_by: d.name)

  def list_clouds, do: Repo.all(from d in Diagram, where: d.kind == "cloud", order_by: d.name)

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

  # ---- cloud versions ------------------------------------------------------

  # Snapshot the cloud's current DSL as the next version.
  def create_version(%Diagram{} = cloud, note \\ nil) do
    next =
      Repo.one(
        from v in CloudVersion,
          where: v.cloud_id == ^cloud.id,
          select: max(v.version)
      ) || 0

    %CloudVersion{}
    |> CloudVersion.changeset(%{
      cloud_id: cloud.id,
      version: next + 1,
      dsl: cloud.dsl || "",
      note: note
    })
    |> Repo.insert()
  end

  def list_versions(cloud_id) do
    Repo.all(from v in CloudVersion, where: v.cloud_id == ^cloud_id, order_by: v.version)
  end

  def get_version!(id), do: Repo.get!(CloudVersion, id)

  # Pin the tree to a specific cloud version: rewrite the `pin <cloud_id>@<v>`
  # line in the tree's DSL. Insert if absent.
  def pin_version(%Diagram{} = tree, cloud_id, version) do
    line = "pin #{cloud_id}@#{version}"

    dsl =
      tree.dsl
      |> String.split("\n")
      |> Enum.reject(&String.match?(&1, ~r/^\s*pin\s+\d+@\d+\s*;?\s*$/))
      |> then(fn lines -> Enum.join(lines ++ [line], "\n") end)

    update_diagram(tree, %{dsl: dsl})
  end

  # ---- injections ----------------------------------------------------------

  def list_injections, do: Repo.all(from i in Injection, order_by: i.id)

  def get_injection!(id), do: Repo.get!(Injection, id)

  def create_injection(attrs) do
    %Injection{}
    |> Injection.changeset(attrs)
    |> Repo.insert()
  end
end
