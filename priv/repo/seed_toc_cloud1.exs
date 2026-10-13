# priv/repo/seed_toc_cloud1.exs
# Seeds the first cloud (Trust vs Speed) + long arrow to a UDE into a new
# TOC diagram, positioned bottom-up (A at bottom, UDE at top).
#
# Run: mix run priv/repo/seed_toc_cloud1.exs
alias FlowspecOps.TOC

# Svelte Flow y increases DOWNWARD, so bottom of tree = high y.
# Layout (bottom -> top):
#   (A)1 objective at y=520
#   (B)1 / (C)1 needs at y=420
#   (D)1 / (D')1 wants at y=320
#   Conflict at y=220
#   IE-1.1 at y=120
#   UDE-1.1.1 at y=20
nodes = [
  # --- Cloud internals ---
  %{id: "a1", class: "Common Objective", number: "1", label: "Reap the benefits of a data center", x: 0, y: 520},
  %{id: "b1", class: "Need", number: "1", label: "Belief that open dialog will facilitate the project being adopted", x: -220, y: 420},
  %{id: "c1", class: "Need", number: "1", label: "Belief that open dialog will block the project", x: 220, y: 420},
  %{id: "d1", class: "Want", number: "1", label: "Invite cooperative dialog with communities", x: -220, y: 320},
  %{id: "d1p", class: "Want", number: "1", label: "Manipulate local politicians", x: 220, y: 320},
  %{id: "conf1", class: "Conflict", number: "", label: "Conflict: Trust vs Speed", x: 0, y: 220},
  # --- Long arrow spine ---
  %{id: "ie11", class: "Intermediate Effect", number: "1.1", label: "Siting and permitting become harder and more expensive", x: 0, y: 120},
  %{id: "ude111", class: "UDE", number: "1.1.1", label: "Public distrusts the AI elite as antidemocratic and self-dealing", x: 0, y: 20},
]

edges = [
  # cloud: objective -> needs -> wants -> conflict
  %{id: "e1", source: "a1", target: "b1"},
  %{id: "e2", source: "a1", target: "c1"},
  %{id: "e3", source: "b1", target: "d1"},
  %{id: "e4", source: "c1", target: "d1p"},
  %{id: "e5", source: "d1", target: "conf1"},
  %{id: "e6", source: "d1p", target: "conf1"},
  # long arrow: conflict -> IE -> UDE
  %{id: "e7", source: "conf1", target: "ie11"},
  %{id: "e8", source: "ie11", target: "ude111"},
]

graph = %{nodes: nodes, edges: edges}

case TOC.create_diagram(%{name: "Cloud 1: Trust vs Speed", graph_json: graph}) do
  {:ok, d} -> IO.puts("Seeded diagram id=#{d.id} with #{length(nodes)} nodes, #{length(edges)} edges")
  {:error, e} -> IO.inspect(e.errors)
end
