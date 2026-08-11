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
      line =
        cond do
          is_nil(node.line_id) -> nil
          true -> Enum.find(factory.lines, &(&1.id == node.line_id))
        end

      versions = Factories.list_versions(factory.id)
      latest = List.first(versions)

      seq =
        case Integer.parse(to_string(Map.get(params, "seq", ""))) do
          {n, _} when n > 0 -> n
          _ -> node.position
        end

      sheet = StationMath.work_cell_sheet(factory, node)
      printed_at = DateTime.utc_now() |> DateTime.truncate(:second)

      conn
      |> put_root_layout(false)
      |> put_layout(false)
      |> assign(:page_title, "Pencil · #{node.name}")
      |> assign(:factory, factory)
      |> assign(:line, line)
      |> assign(:node, node)
      |> assign(:seq, seq)
      |> assign(:sheet, sheet)
      |> assign(:latest_version, latest)
      |> assign(:printed_at, printed_at)
      |> render(:work_cell)
    end
  end

  defp parse_id!(id) when is_integer(id), do: id

  defp parse_id!(id) when is_binary(id) do
    case Integer.parse(id) do
      {n, _} -> n
      :error -> raise Ecto.NoResultsError, queryable: FlowspecOps.Factories.FactoryNode
    end
  end
end
