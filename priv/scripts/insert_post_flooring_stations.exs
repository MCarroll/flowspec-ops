
# Insert: Logistics Move → Sprayfoam Utility Prep → Spray Foam after Flooring
# Flooring: id=12, factory_id=1, line_id=3, position=4
# Shifts Insulation(5→8), Walls(6→9), S3(7→10) before inserting new nodes at 5,6,7.

import Ecto.Query

alias FlowspecOps.Repo
alias FlowspecOps.Factories.FactoryNode
alias FlowspecOps.Factories.FactoryNodeStep
alias FlowspecOps.Factories.FactoryNodeStepItem
alias FlowspecOps.Factories.FactoryLink

factory_id = 1
line_id = 3

# ── 1. Shift existing nodes out of the way (descending to avoid unique clash) ──

for {node_id, new_pos} <- [{13, 10}, {10, 9}, {9, 8}] do
  node = Repo.get!(FactoryNode, node_id)
  {:ok, _} = Repo.update(Ecto.Changeset.change(node, position: new_pos))
  IO.puts("  Shifted node #{node_id} (#{node.name}) → position #{new_pos}")
end

# ── 2. Create Logistics Move (position 5) ──

{:ok, logistics} =
  %FactoryNode{}
  |> FactoryNode.changeset(%{
    factory_id: factory_id,
    line_id: line_id,
    kind: :work_cell,
    name: "Logistics Move",
    position: 5,
    note: "Rotation + crane lift transfer between bays. 3 riggers.",
    crew_size: 3
  })
  |> Repo.insert()

IO.puts("  Created: Logistics Move  id=#{logistics.id} pos=5")

{:ok, step_logistics} =
  %FactoryNodeStep{}
  |> FactoryNodeStep.changeset(%{
    factory_node_id: logistics.id,
    name: "Rotate, lift & transfer",
    position: 1,
    people: 3,
    shared: false  # crane/gang step: one gang, one move — crew is demand only, not time compression
  })
  |> Repo.insert()

IO.puts("    Step: #{step_logistics.name}  id=#{step_logistics.id}")

{:ok, harness} =
  %FactoryNodeStepItem{}
  |> FactoryNodeStepItem.changeset(%{
    factory_node_step_id: step_logistics.id,
    kind: :equipment,
    name: "Harness kit",
    qty: 3.0,
    position: 1
  })
  |> Repo.insert()

IO.puts("    Item: #{harness.name}  id=#{harness.id}")

# ── 3. Create Sprayfoam Utility Prep (position 6, slots 3) ──

{:ok, util_prep} =
  %FactoryNode{}
  |> FactoryNode.changeset(%{
    factory_id: factory_id,
    line_id: line_id,
    kind: :work_cell,
    name: "Sprayfoam Utility Prep",
    position: 6,
    slots: 3
  })
  |> Repo.insert()

IO.puts("  Created: Sprayfoam Utility Prep  id=#{util_prep.id} pos=6 slots=3")

for {name, pos} <- [
  {"RockWool blocking (floor)", 1},
  {"Fire sprinkler mounts (ceiling)", 2},
  {"Ceiling joist mounts", 3}
] do
  {:ok, s} =
    %FactoryNodeStep{}
    |> FactoryNodeStep.changeset(%{
      factory_node_id: util_prep.id,
      name: name,
      position: pos
    })
    |> Repo.insert()

  IO.puts("    Step #{pos}: #{s.name}  id=#{s.id}")
end

# ── 4. Create Spray Foam (position 7, slots 3) ──

{:ok, spray_foam} =
  %FactoryNode{}
  |> FactoryNode.changeset(%{
    factory_id: factory_id,
    line_id: line_id,
    kind: :work_cell,
    name: "Spray Foam",
    position: 7,
    slots: 3,
    note: "Spray crew 2 on active spray steps. Cure steps are dwells — no labor charged."
  })
  |> Repo.insert()

IO.puts("  Created: Spray Foam  id=#{spray_foam.id} pos=7 slots=3")

# Steps: active steps have people=2; cure dwells have people=nil
spray_steps = [
  {"Spray prep",            1, 2},
  {"Spray foam (ceiling)",  2, 2},
  {"Spray foam (floor)",    3, 2},
  {"Spray foam cure",       4, nil},
  {"Spray Fireshell",       5, 2},
  {"Fireshell cure",        6, nil}
]

for {name, pos, people} <- spray_steps do
  attrs =
    %{factory_node_id: spray_foam.id, name: name, position: pos}
    |> then(fn a -> if people, do: Map.put(a, :people, people), else: a end)

  {:ok, s} =
    %FactoryNodeStep{}
    |> FactoryNodeStep.changeset(attrs)
    |> Repo.insert()

  IO.puts("    Step #{pos}: #{s.name}  people=#{inspect(people)}  id=#{s.id}")
end

# ── 5. Delete old Flooring→Insulation and Flooring→S3 links ──

old_link_ids = [16, 17]

for link_id <- old_link_ids do
  link = Repo.get!(FactoryLink, link_id)
  {:ok, _} = Repo.delete(link)
  IO.puts("  Deleted link id=#{link_id}")
end

# ── 6. Create new link chain ──

flooring_id   = 12
insulation_id = 9
s3_id         = 13

new_links = [
  {flooring_id,        logistics.id,   "Flooring → Logistics Move"},
  {logistics.id,       util_prep.id,   "Logistics Move → Sprayfoam Utility Prep"},
  {util_prep.id,       spray_foam.id,  "Sprayfoam Utility Prep → Spray Foam"},
  {spray_foam.id,      insulation_id,  "Spray Foam → Insulation"},
  {spray_foam.id,      s3_id,          "Spray Foam → S3"}
]

for {from_id, to_id, label} <- new_links do
  {:ok, l} =
    %FactoryLink{}
    |> FactoryLink.changeset(%{factory_id: factory_id, from_node_id: from_id, to_node_id: to_id})
    |> Repo.insert()

  IO.puts("  Link #{l.id}: #{label}")
end

IO.puts("\nDone. Summary:")
IO.puts("  Nodes: Logistics Move id=#{logistics.id} pos=5 | Sprayfoam Utility Prep id=#{util_prep.id} pos=6 slots=3 | Spray Foam id=#{spray_foam.id} pos=7 slots=3")
IO.puts("  Shifted: Insulation→8, Walls→9, S3→10")
IO.puts("  Links: Flooring→LogMove→UtilPrep→SprayFoam→{Insulation,S3}")
IO.puts("  Assumptions: cure step minutes left blank (unknown); harness kit qty=3 per step, no cost entered.")
