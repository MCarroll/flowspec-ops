defmodule FlowspecOps.BOMs do
  import Ecto.Query
  alias FlowspecOps.Repo
  alias FlowspecOps.BOMs.BOM
  alias FlowspecOps.BOMs.BOMItem

  def list_boms(project_id) do
    Repo.all(from b in BOM, where: b.project_id == ^project_id, order_by: [asc: b.design_name, asc: b.version])
  end

  def get_bom!(id) do
    Repo.get!(BOM, id)
    |> Repo.preload(items: [:part, :manufactured_by, :installed_by, :parent])
  end

  def create_bom(attrs) do
    %BOM{}
    |> BOM.changeset(attrs)
    |> Repo.insert()
  end

  def update_bom(%BOM{} = bom, attrs) do
    bom
    |> BOM.changeset(attrs)
    |> Repo.update()
  end

  def delete_bom(%BOM{} = bom), do: Repo.delete(bom)

  def create_bom_item(attrs) do
    %BOMItem{}
    |> BOMItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_bom_item(%BOMItem{} = item, attrs) do
    item
    |> BOMItem.changeset(attrs)
    |> Repo.update()
  end

  def delete_bom_item(%BOMItem{} = item), do: Repo.delete(item)

  def list_bom_items(bom_id) do
    Repo.all(from i in BOMItem, where: i.bom_id == ^bom_id, order_by: i.position, preload: [:part, :manufactured_by, :installed_by, :parent])
  end
end
