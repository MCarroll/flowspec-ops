defmodule FlowspecOps.Repo.Migrations.AddCloudKindVersionsAndInjections do
  use Ecto.Migration

  def change do
    # Diagrams split into two kinds: trees (CRTs) and clouds (CRD surfaces).
    # Existing diagrams are trees.
    alter table(:toc_diagrams) do
      add :kind, :string, default: "tree", null: false
    end

    # Cloud versions: a cloud is a record; each version is a snapshot of its
    # DSL. A CRT pins one version; swap = repoint the pin.
    create table(:cloud_versions) do
      add :cloud_id, references(:toc_diagrams, on_delete: :delete_all), null: false
      add :version, :integer, null: false
      add :dsl, :text
      add :note, :string
      timestamps()
    end

    create unique_index(:cloud_versions, [:cloud_id, :version])

    # Injections: DB-numbered records. The id IS the number. Postulated once
    # (from a cloud or a tree), referenced by both.
    create table(:injections) do
      add :text, :text, null: false
      add :note, :string
      timestamps()
    end
  end
end
