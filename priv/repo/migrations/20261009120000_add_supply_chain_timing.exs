defmodule FlowspecOps.Repo.Migrations.AddSupplyChainTiming do
  use Ecto.Migration

  def change do
    # Order date anchors the supplier/transport step chain; ETA at dock = order_date + Σ step durations.
    alter table(:factory_nodes) do
      add :order_date, :date
    end

    # Day/week duration for supply-chain steps (Order 1w, MFG 2w, Transit 3d). Work-cell steps keep estimated_minutes.
    alter table(:factory_node_steps) do
      add :duration_days, :integer
    end
  end
end
