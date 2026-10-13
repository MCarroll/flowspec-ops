defmodule FlowspecOps.Repo.Migrations.AddDslToTocDiagrams do
  use Ecto.Migration

  def change do
    alter table(:toc_diagrams) do
      add :dsl, :text
    end
  end
end
