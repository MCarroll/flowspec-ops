defmodule FlowspecOps.Repo.Migrations.CreateFactories do
  use Ecto.Migration

  def change do
    create table(:factories) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :client_id, references(:clients, on_delete: :restrict), null: false

      timestamps()
    end

    create unique_index(:factories, [:slug])
    create index(:factories, [:client_id])
  end
end
