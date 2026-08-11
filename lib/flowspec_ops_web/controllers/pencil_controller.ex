defmodule FlowspecOpsWeb.PencilController do
  use FlowspecOpsWeb, :controller

  alias FlowspecOps.Factories
  alias FlowspecOps.Factories.StationMath

  def show(conn, %{"factory_id" => factory_id, "node_id" => node_id} = params) do
    factory = Factories.get_factory!(factory_id)
    node_id = parse_id!(node_id)
    node = Enum.find(factory.nodes, &(&1.id == node_id))

    if is_nil(node) do
      conn
      |> put_status(:not_found)
      |> text("Node not found")
    else
      line = find_line(factory, node.line_id)
      latest = factory.id |> Factories.list_versions() |> List.first()
      seq = parse_seq(params, node.position)
      printed_at = DateTime.utc_now() |> DateTime.truncate(:second)

      conn =
        conn
        |> put_root_layout(false)
        |> put_layout(false)
        |> assign(:factory, factory)
        |> assign(:line, line)
        |> assign(:seq, seq)
        |> assign(:latest_version, latest)
        |> assign(:printed_at, printed_at)

      case node.kind do
        :work_cell ->
          conn
          |> assign(:page_title, "Pencil · #{node.name}")
          |> assign(:node, node)
          |> assign(:sheet, StationMath.work_cell_sheet(factory, node))
          |> render(:work_cell)

        :queue ->
          conn
          |> assign(:page_title, "Pencil · #{node.name}")
          |> assign(:node, node)
          |> assign(:role_label, queue_role_label(node.queue_role))
          |> assign(:link_rows, link_rows(factory, node))
          |> render(:queue)

        _ ->
          conn
          |> put_status(:not_found)
          |> text("Pencil sheet not available for this card kind yet")
      end
    end
  end

  def storage_group(conn, %{"factory_id" => factory_id} = params) do
    factory = Factories.get_factory!(factory_id)
    group_name = params |> Map.get("group", "") |> to_string() |> String.trim()

    members =
      factory.nodes
      |> Enum.filter(fn n ->
        n.kind == :queue and is_binary(n.storage_group) and n.storage_group == group_name
      end)
      |> Enum.sort_by(& &1.position)

    if group_name == "" or members == [] do
      conn
      |> put_status(:not_found)
      |> text("Storage group not found")
    else
      line_id = members |> hd() |> Map.get(:line_id)
      line = find_line(factory, line_id)
      latest = factory.id |> Factories.list_versions() |> List.first()
      seq = parse_seq(params, 1)
      printed_at = DateTime.utc_now() |> DateTime.truncate(:second)

      total_slots =
        members
        |> Enum.map(fn m -> m.slots || 0 end)
        |> Enum.sum()

      steps =
        members
        |> List.first()
        |> case do
          nil -> []
          lot -> lot.steps || []
        end
        |> Enum.sort_by(& &1.position)

      line_nodes = (line && Map.get(line, :nodes)) || factory.nodes
      flooring = Enum.find(line_nodes, &(&1.name == "Flooring"))

      conn
      |> put_root_layout(false)
      |> put_layout(false)
      |> assign(:page_title, "Pencil · #{group_name} LOT")
      |> assign(:factory, factory)
      |> assign(:line, line)
      |> assign(:seq, seq)
      |> assign(:latest_version, latest)
      |> assign(:printed_at, printed_at)
      |> assign(:group_name, group_name)
      |> assign(:members, members)
      |> assign(:total_slots, total_slots)
      |> assign(:steps, steps)
      |> assign(:passthrough_name, flooring && flooring.name)
      |> assign(:passthrough_slots, flooring && flooring.slots)
      |> render(:storage_group)
    end
  end

  defp find_line(_factory, nil), do: nil

  defp find_line(factory, line_id) do
    Enum.find(factory.lines, &(&1.id == line_id))
  end

  defp parse_seq(params, default) do
    case Integer.parse(to_string(Map.get(params, "seq", ""))) do
      {n, _} when n > 0 -> n
      _ -> default
    end
  end

  defp parse_id!(id) when is_integer(id), do: id

  defp parse_id!(id) when is_binary(id) do
    case Integer.parse(id) do
      {n, _} -> n
      :error -> raise Ecto.NoResultsError, queryable: FlowspecOps.Factories.FactoryNode
    end
  end

  defp queue_role_label(:storage_lot), do: "Storage lot"
  defp queue_role_label(:feeding_buffer), do: "Feeding buffer"
  defp queue_role_label(:queue), do: "Queue"
  defp queue_role_label(_), do: "Queue"

  defp link_rows(factory, node) do
    inbound =
      factory.links
      |> Enum.filter(&(&1.to_node_id == node.id && &1.from_node))
      |> Enum.map(fn l ->
        %{
          dir: "in",
          name: l.from_node.name,
          kind: l.from_node.kind,
          label: l.label
        }
      end)

    outbound =
      factory.links
      |> Enum.filter(&(&1.from_node_id == node.id && &1.to_node))
      |> Enum.map(fn l ->
        %{
          dir: "out",
          name: l.to_node.name,
          kind: l.to_node.kind,
          label: l.label
        }
      end)

    inbound ++ outbound
  end
end
