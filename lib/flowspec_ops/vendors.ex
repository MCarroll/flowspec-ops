defmodule FlowspecOps.Vendors do
  import Ecto.Query
  alias FlowspecOps.Repo
  alias FlowspecOps.Vendors.Vendor

  def list_vendors do
    Repo.all(from v in Vendor, order_by: v.name)
  end

  def get_vendor!(id), do: Repo.get!(Vendor, id)

  def create_vendor(attrs) do
    %Vendor{}
    |> Vendor.changeset(attrs)
    |> Repo.insert()
  end

  def update_vendor(%Vendor{} = vendor, attrs) do
    vendor
    |> Vendor.changeset(attrs)
    |> Repo.update()
  end

  def delete_vendor(%Vendor{} = vendor), do: Repo.delete(vendor)
end
