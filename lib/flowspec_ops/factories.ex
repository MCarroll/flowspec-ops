defmodule FlowspecOps.Factories do
  import Ecto.Query

  alias FlowspecOps.Repo
  alias FlowspecOps.Factories.Factory
  alias FlowspecOps.Factories.FactoryLine
  alias FlowspecOps.Factories.FactoryLink
  alias FlowspecOps.Factories.FactorySku
  alias FlowspecOps.Factories.FactoryNode
  alias FlowspecOps.Factories.FactoryNodeStep
alias FlowspecOps.Factories.FactoryNodeStepItem
  alias FlowspecOps.Factories.Versioning

  # --- Versions / milestones ---

  defdelegate assert_schema_parity(), to: Versioning
  defdelegate schema_parity_errors(), to: Versioning
  defdelegate list_versions(factory_id), to: Versioning
  defdelegate save_version(factory, attrs), to: Versioning
  defdelegate restore_version(factory, version_id), to: Versioning
  defdelegate restore_version(factory, version_id, opts), to: Versioning

  def list_factories do
    Repo.all(from f in Factory, order_by: f.name, preload: [:client])
  end

  def get_factory!(id) do
    Repo.get!(Factory, id)
    |> Repo.preload([
      :client,
      :skus,
      links: [:from_node, :to_node],
      lines: [nodes: [steps: :items]],
      nodes: [steps: :items]
    ])
  end

  def update_factory(%Factory{} = factory, attrs) do
    factory
    |> Factory.changeset(attrs)
    |> Repo.update()
  end

  # --- Lines ---

  def create_line(attrs) do
    %FactoryLine{}
    |> FactoryLine.changeset(attrs)
    |> Repo.insert()
  end

  # --- SKUs ---

  def create_sku(attrs) do
    %FactorySku{}
    |> FactorySku.changeset(attrs)
    |> Repo.insert()
  end

  # --- Links ---

  def create_link(attrs) do
    %FactoryLink{}
    |> FactoryLink.changeset(attrs)
    |> Repo.insert()
  end

  # --- Nodes ---

  def list_nodes(factory_id) do
    Repo.all(
      from n in FactoryNode,
        where: n.factory_id == ^factory_id,
        order_by: n.position,
        preload: [steps: :items]
    )
  end

  def create_node(attrs) do
    %FactoryNode{}
    |> FactoryNode.changeset(attrs)
    |> Repo.insert()
  end

  def update_node(node, attrs) do
    node
    |> FactoryNode.changeset(attrs)
    |> Repo.update()
  end

  def delete_node(node), do: Repo.delete(node)

  # Move node up within its group (same line_id), swapping positions.
  def move_node_up(node, all_nodes) do
    prev =
      all_nodes
      |> Enum.filter(fn n -> same_group?(node, n) && n.position < node.position end)
      |> Enum.sort_by(& &1.position)
      |> List.last()

    case prev do
      nil -> {:ok, :no_op}
      _ -> swap_node_positions(node, prev)
    end
  end

  # Move node down within its group (same line_id), swapping positions.
  def move_node_down(node, all_nodes) do
    next =
      all_nodes
      |> Enum.filter(fn n -> same_group?(node, n) && n.position > node.position end)
      |> Enum.sort_by(& &1.position)
      |> List.first()

    case next do
      nil -> {:ok, :no_op}
      _ -> swap_node_positions(node, next)
    end
  end

  defp same_group?(a, b), do: a.line_id == b.line_id

  # Three-step swap using -1 as a safe temporary position.
  # Works with PostgreSQL immediate constraint checking: each UPDATE is
  # checked atomically and -1 is never a real node position.
  defp swap_node_positions(node_a, node_b) do
    pos_a = node_a.position
    pos_b = node_b.position

    Ecto.Multi.new()
    |> Ecto.Multi.update(:temp, Ecto.Changeset.change(node_a, position: -1))
    |> Ecto.Multi.update(:node_b, Ecto.Changeset.change(node_b, position: pos_a))
    |> Ecto.Multi.update(:node_a, Ecto.Changeset.change(node_a, position: pos_b))
    |> Repo.transaction()
  end

  # --- Steps ---

  def create_step(attrs) do
    %FactoryNodeStep{}
    |> FactoryNodeStep.changeset(attrs)
    |> Repo.insert()
  end

  def update_step(step, attrs) do
    step
    |> FactoryNodeStep.changeset(attrs)
    |> Repo.update()
  end

  def delete_step(step), do: Repo.delete(step)

  # --- Step items (equipment / materials) ---

  def create_step_item(attrs) do
    %FactoryNodeStepItem{}
    |> FactoryNodeStepItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_step_item(item, attrs) do
    item
    |> FactoryNodeStepItem.changeset(attrs)
    |> Repo.update()
  end

  def delete_step_item(item), do: Repo.delete(item)
end
