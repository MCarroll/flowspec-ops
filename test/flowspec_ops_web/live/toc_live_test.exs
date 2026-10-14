defmodule FlowspecOpsWeb.TocLiveTest do
  use FlowspecOpsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias FlowspecOps.TOC

  test "clouds page lists only kind=cloud; trees page only kind=tree", %{conn: conn} do
    {:ok, _} = TOC.create_diagram(%{name: "A Tree", kind: "tree", dsl: "node ude1: UndesirableEffect \"X\";"})
    {:ok, _} = TOC.create_diagram(%{name: "A Cloud", kind: "cloud", dsl: "cloud cc1:"})

    {:ok, _view, clouds_html} = live(conn, ~p"/toc/clouds")
    assert clouds_html =~ "A Cloud"
    refute clouds_html =~ "A Tree"

    {:ok, _view, trees_html} = live(conn, ~p"/toc")
    assert trees_html =~ "A Tree"
    refute trees_html =~ "A Cloud"
  end

  test "kind validation rejects anything but tree/cloud" do
    assert {:ok, cloud} = TOC.create_diagram(%{name: "C", kind: "cloud"})
    assert cloud.kind == "cloud"

    assert {:ok, tree} = TOC.create_diagram(%{name: "T", kind: "tree"})
    assert tree.kind == "tree"

    assert {:error, _} = TOC.create_diagram(%{name: "Bad", kind: "widget"})
  end

  test "cloud versions snapshot sequentially", %{conn: _conn} do
    {:ok, cloud} = TOC.create_diagram(%{name: "V Cloud", kind: "cloud", dsl: "cloud cc1:"})

    {:ok, v1} = TOC.create_version(cloud, "first")
    assert v1.version == 1

    {:ok, _} = TOC.update_diagram(cloud, %{dsl: "cloud cc1:\nnode a1: CommonObjective \"A\";"})
    {:ok, v2} = TOC.create_version(cloud, nil)
    assert v2.version == 2

    assert length(TOC.list_versions(cloud.id)) == 2
  end
end
