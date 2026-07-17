defmodule FlowspecOpsWeb.ClientsLiveTest do
  use FlowspecOpsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders sample intake client", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/clients")

    assert html =~ "Sample Intake"
    assert html =~ "Intake Coordinator"
  end
end
