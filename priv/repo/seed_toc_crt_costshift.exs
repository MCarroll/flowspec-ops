# priv/repo/seed_toc_crt_costshift.exs
# Seeds the governance CRT from the Spears "Solving the AI Power Problem" video:
# no standard rules -> cost shifting -> community harms -> bans -> displacement.
# Water is the most legible symptom branch, not the trunk.
# Run: mix run priv/repo/seed_toc_crt_costshift.exs
alias FlowspecOps.TOC

dsl = """
# --- Root causes (bottom of the tree) ---
# CLR: cause exists, no evidence of insufficiency — each is independently
# necessary; together they explain the trunk.
node ie1: IntermediateEffect "No standard governance rules for data centers; developer pledges are voluntary";
node ie2: IntermediateEffect "Utilities earn guaranteed returns on infrastructure, not on optimization";
node ie3: IntermediateEffect "Grid neglected for decades; century-old centralized design";
node ie4: IntermediateEffect "Permitting and interconnection broken; transmission takes 10+ years";

# --- Trunk mechanism ---
node ie5: IntermediateEffect "Clean energy cannot come online fast enough to meet AI load";
node ie6: IntermediateEffect "Developers site where land, power, and water are cheapest";
node ie7: IntermediateEffect "Cheap land, power, water cluster in rural water-stressed low-income areas";
node ie8: IntermediateEffect "Utilities build gas plants instead of flexibility and batteries";

# --- Impact branches ---
node ie9: IntermediateEffect "Data centers draw down local water supplies";
node ie10: IntermediateEffect "Sites concentrate in water-stressed, high-pollution, low-income areas";
node ie11: IntermediateEffect "Local electricity rates rise to fund grid upgrades";
node ie12: IntermediateEffect "Communities face pollution, water depletion, and rate hikes";
node ie13: IntermediateEffect "Grid locks into fossil fuels for 40-year plant lifecycles";
node ie14: IntermediateEffect "Benefits flow to developers; communities capture little";

# --- UDEs ---
# CLR Level III (cause insufficiency): cost shifting = harms AND benefits
# captured elsewhere. That conjunction is exactly the video's definition,
# so it gets the AND-junctor.
node ude1: UndesirableEffect "Communities bear the harms while corporations capture the benefits";
node ude2: UndesirableEffect "AI buildout locks the grid into natural gas";
node ude3: UndesirableEffect "Residents pay rising rates for infrastructure that does not serve them";
node ude4: UndesirableEffect "Data center harms simply move to the next community; nothing is solved";
node and1: AndJunctior;

# --- Displacement chain (bans punt, they don't solve) ---
node ie15: IntermediateEffect "Public trust in developers and government collapses";
node ie16: IntermediateEffect "Communities organize and win bans and moratoria";
node ie17: IntermediateEffect "Bans displace projects to less-resourced communities";
node ie18: IntermediateEffect "Harms recur elsewhere; the system is unchanged";

# --- Solutions stuck in pilot ---
node ie19: IntermediateEffect "Grid flexibility, heat reuse, liquid cooling stay in pilot form";
node ie20: IntermediateEffect "No regulation or investment makes better tech the standard";

# --- Edges: causes feed up, effects stack on top ---
edge ie1 -> ie14
edge ie1 -> ie19
edge ie2 -> ie8
edge ie2 -> ie19
edge ie3 -> ie5
edge ie4 -> ie5
edge ie5 -> ie11
edge ie5 -> ie8
edge ie6 -> ie9
edge ie6 -> ie10
edge ie7 -> ie10
edge ie8 -> ie11
edge ie8 -> ie13
edge ie9 -> ie12
edge ie10 -> ie12
edge ie11 -> ie12
edge ie12 -> and1
edge ie14 -> and1
edge and1 -> ude1
edge ie13 -> ude2
edge ie11 -> ude3
edge ie12 -> ude3
edge ude1 -> ie15
edge ie15 -> ie16
edge ie16 -> ie17
edge ie17 -> ie18
edge ie18 -> ude4
edge ie19 -> ie20
edge ie20 -> ie8
"""

case TOC.list_diagrams() |> Enum.find(&(&1.name == "CRT: AI Power Boom Cost Shifting")) do
  nil ->
    case TOC.create_diagram(%{name: "CRT: AI Power Boom Cost Shifting", dsl: dsl}) do
      {:ok, d} -> IO.puts("created diagram #{d.id}")
      {:error, e} -> IO.inspect(e.errors)
    end

  d ->
    case TOC.update_diagram(d, %{dsl: dsl}) do
      {:ok, u} -> IO.puts("updated diagram #{u.id}")
      {:error, e} -> IO.inspect(e.errors)
    end
end

# Runnable check: every edge endpoint must resolve to a node, and the AND-
# junctor must have exactly two inbound legs (else the cloud logic misleads).
parsed = FlowspecOps.TOC.DSL.parse(dsl)
ids = MapSet.new(parsed.nodes, & &1.id)
dangling = Enum.filter(parsed.edges, fn e -> not (MapSet.member?(ids, e.from) and MapSet.member?(ids, e.to)) end)
and1_in = Enum.count(parsed.edges, &(&1.to == "and1"))

if dangling == [] and and1_in == 2 do
  IO.puts("OK: #{length(parsed.nodes)} nodes, #{length(parsed.edges)} edges, and1 has #{and1_in} legs")
else
  IO.puts("FAIL: dangling=#{inspect(dangling)} and1_in=#{and1_in}")
end
