defmodule FlowspecOps.Factories.VersionSchemaParityTest do
  use FlowspecOps.DataCase, async: false

  alias FlowspecOps.Repo
  alias FlowspecOps.Factories
  alias FlowspecOps.Factories.Versioning
  alias FlowspecOps.Sales.Client

  describe "VERSION SCHEMA PARITY" do
    test "primary tables match version twins (seatbelt — do not ignore)" do
      case Versioning.assert_schema_parity() do
        :ok ->
          assert true

        {:error, errors} ->
          flunk("""
          VERSION SCHEMA PARITY FAILED
          Milestone Save is blocked until fixed.
          #{Enum.join(errors, "\n")}
          """)
      end
    end
  end

  describe "save and restore milestone" do
setup do
      slug = "parity-co-#{System.unique_integer([:positive])}"

      {:ok, client} =
        %Client{}
        |> Client.changeset(%{
          name: "Parity Co",
          short_name: "Parity",
          slug: slug,
          stage: :engaged
        })
        |> Repo.insert()

      {:ok, factory} =
        %FlowspecOps.Factories.Factory{}
        |> FlowspecOps.Factories.Factory.changeset(%{
          name: "VA Test",
          slug: "va-test-#{System.unique_integer([:positive])}",
          client_id: client.id,
          target_qty: 100,
          window_days: 20
        })
        |> Repo.insert()

      {:ok, line} =
        Factories.create_line(%{factory_id: factory.id, name: "Main", position: 1})

      {:ok, node} =
        Factories.create_node(%{
          factory_id: factory.id,
          line_id: line.id,
          kind: "work_cell",
          name: "Flooring",
          position: 1,
          slots: 6,
          crew_size: 4
        })

      {:ok, step} =
        Factories.create_step(%{
          factory_node_id: node.id,
          name: "Lay deck",
          position: 1,
          people: 4,
          estimated_minutes: 45
        })

      {:ok, _item} =
        Factories.create_step_item(%{
          factory_node_step_id: step.id,
          kind: "equipment",
          name: "Nailer",
          qty: 2.0,
          unit_cost_cents: 12_000,
          position: 1
        })

      factory = Factories.get_factory!(factory.id)
      %{factory: factory, node: node, step: step}
    end

    test "save milestone copies graph; restore brings it back after wipe-class edit", %{
      factory: factory,
      node: node
    } do
      assert {:ok, version} =
               Versioning.save_version(factory, %{name: "Good enough for Reed", note: "pre-call"})

      assert version.name == "Good enough for Reed"
      versions = Versioning.list_versions(factory.id)
      assert Enum.any?(versions, &(&1.id == version.id))

      # Mutate working copy
      assert {:ok, _} = Factories.update_node(node, %{name: "Flooring WIP", slots: 99})
      factory = Factories.get_factory!(factory.id)
      assert Enum.find(factory.nodes, &(&1.id == node.id)).name == "Flooring WIP"

      assert {:ok, _} = Versioning.restore_version(factory, version.id)
      factory = Factories.get_factory!(factory.id)

      restored = Enum.find(factory.nodes, &(&1.name == "Flooring"))
      assert restored
      assert restored.slots == 6
      assert length(restored.steps) == 1
      assert hd(restored.steps).name == "Lay deck"
      assert length(hd(restored.steps).items) == 1

      # Safety auto version was created
      names = factory.id |> Versioning.list_versions() |> Enum.map(& &1.name)
assert Enum.any?(names, &String.starts_with?(&1, "Auto before restore"))
    end
  end
end
