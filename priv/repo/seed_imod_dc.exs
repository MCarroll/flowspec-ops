# iMod DC project: two storage cards, 12 slots x 2 iMod frames each (24 frames).
#
# One line, two queue cards (queue_role: :storage_lot):
#   seq 1  Outside Storage — vendor Singamas, outside the factory
#   seq 2  Inside Storage  — internal, inside the factory
#
# Idempotent: wipes and rebuilds this project's net on every run, so card data
# can be re-seeded as it gets fixed during build-and-test.
#
#   mix run priv/repo/seed_imod_dc.exs

alias FlowspecOps.{Repo, Factories}
alias FlowspecOps.Factories.{Factory, FactoryNode, FactoryLine, MasterProductionLine, FactoryLink}
import Ecto.Query

client = Repo.get_by(FlowspecOps.Sales.Client, slug: "imod") ||
  raise "client 'imod' not found — run priv/repo/seeds.exs first"

# The ×2-per-slot lives in the manifest row's Qty; slots stays 12.
part = Repo.get_by(FlowspecOps.Parts.Part, part_number: "IM-40x8x96") ||
  raise "part IM-40x8x96 not found"

factory =
  Repo.get_by(Factory, slug: "imod-dc") ||
    Repo.insert!(%Factory{name: "iMod DC", slug: "imod-dc", client_id: client.id})

# Children before parents, or the FK constraints refuse the delete.
Repo.delete_all(from l in FactoryLink, where: l.factory_id == ^factory.id)
Repo.delete_all(from n in FactoryNode, where: n.factory_id == ^factory.id)
Repo.delete_all(from l in FactoryLine, where: l.factory_id == ^factory.id)
Repo.delete_all(from m in MasterProductionLine, where: m.factory_id == ^factory.id)

{:ok, mpl} = Factories.create_master_production_line(%{
  factory_id: factory.id,
  name: "iMod DC Frame"
})

{:ok, line} = Factories.create_line(%{
  factory_id: factory.id,
  master_production_line_id: mpl.id,
  name: "Frame Storage",
  position: 1
})

storage_cards = [
  %{
    name: "Outside Storage",
    position: 1,
    location: "Outside the factory",
    vendor_id: Repo.get_by(FlowspecOps.Vendors.Vendor, name: "Singamas") && Repo.get_by(FlowspecOps.Vendors.Vendor, name: "Singamas").id,
    note: "24 iMod frames (12 slots × 2)"
  },
  %{
    name: "Inside Storage",
    position: 2,
    location: "Inside the factory",
    vendor_id: nil,
    note: "24 iMod frames (12 slots × 2)"
  }
]

nodes =
  Enum.map(storage_cards, fn card ->
    {:ok, node} = Factories.create_node(%{
      factory_id: factory.id,
      line_id: line.id,
      kind: :queue,
      queue_role: :storage_lot,
      slots: 12,
      part_id: part.id,
      vendor_id: card.vendor_id,
      vendor_name: nil,
      name: card.name,
      position: card.position,
      location: card.location,
      note: card.note
    })
    node
  end)

# Outside → Inside: one link, the frame's move into the factory.
{:ok, _link} = Factories.create_link(%{
  factory_id: factory.id,
  from_node_id: List.first(nodes).id,
  to_node_id: List.last(nodes).id
})

IO.puts("""

iMod DC ready.
  factory  #{factory.id}  /factory/projects/#{factory.id}
  cards    Outside Storage (12 slots) → Inside Storage (12 slots)
  part     #{part.name} (#{part.part_number})
""")
