defmodule FlowspecOps.Repo.Migrations.DropGraphJsonFromTocDiagrams do
  use Ecto.Migration

  def change do
    alter table(:toc_diagrams) do
      remove :graph_json
    end
  end
end
