defmodule FlowspecOps.Repo.Migrations.AddDesignChecksToFactoryNodes do
  use Ecto.Migration

  def change do
    alter table(:factory_nodes) do
      add :product_ready, :boolean, null: false, default: false
      add :method_instruction, :boolean, null: false, default: false
    end
  end
end
