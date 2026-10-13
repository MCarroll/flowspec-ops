defmodule FlowspecOps.Repo.Migrations.CreateTocDiagrams do
  use Ecto.Migration

  def change do
    create table(:toc_diagrams) do
      add :name, :string, null: false
      add :graph_json, :map, null: false, default: %{}

      timestamps()
    end

    create unique_index(:toc_diagrams, [:name])
  end
end
