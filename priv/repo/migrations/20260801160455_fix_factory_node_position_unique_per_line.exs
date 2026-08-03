defmodule FlowspecOps.Repo.Migrations.FixFactoryNodePositionUniquePerLine do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index(:factory_nodes, [:factory_id, :position])

    # Position is unique within a line (or within ungrouped nodes where line_id is null).
    create unique_index(:factory_nodes, [:factory_id, :line_id, :position],
             name: :factory_nodes_factory_id_line_id_position_index
           )
  end
end
