# priv/repo/seed_toc_cloud1.exs
# Seeds the refined CRT: D' -> IE chain -> UDE, split entities + AND-junctor.
# Run: mix run priv/repo/seed_toc_cloud1.exs
alias FlowspecOps.TOC

dsl = """
# --- Cloud floor (Dettmer: stood on its point, A at top) ---
cloud cc1: a1 b1 c1 d1 d1p
node a1: CommonObjective "Reap the benefits of a data center";
node b1: Need "Belief that open dialog will facilitate the project being adopted";
node c1: Need "Belief that open dialog will block the project";
node d1: Want "Invite cooperative dialog with communities";
node d1p: Want "Manipulate local politicians to bypass public comment";
edge a1 -> b1
edge a1 -> c1
edge b1 -> d1
edge c1 -> d1p

# --- Stable badge numbers (renumber only on explicit ask) ---
number ude2: 1.0
number ie4: 1.1
number ie3: 1.2
number ie10: 1.3
number ie11: 1.4
number ie12: 1.5
number ie14: 1.6
number ie9: 1.7
number ie13: 1.8
number ie15: 1.9
number ie2: 1.10
number ie1: 1.11
number ie6: 1.12
number ie8: 1.13
number ie7: 1.14
number ie5: 1.15
number ie16: 1.16
number ie17: 1.17
number ie18: 1.18
number ie19: 1.19
number ie20: 1.20
number ie21: 1.21
number ie22: 1.22
number ie23: 1.23
number ie24: 1.24
number ie25: 1.25
number ie26: 1.26
number ie27: 1.27

# --- The long arrow from D' filled in with IEs ---
node ie1: IntermediateEffect "DC directors face intense pressure to accelerate approval";
node ie2: IntermediateEffect "Directors wine-and-dine and pressure city/county leaders, who sign NDAs and hold back-channel talks with AI principals";
node ie3: IntermediateEffect "Mandatory public notices reveal the manipulation and the NDA'd back-channel deals";
node ie4: IntermediateEffect "Public anger escalates toward threats against elected and appointed leadership";
node ie16: IntermediateEffect "Public distrusts the AI elite as antidemocratic and self-dealing";
node ude2: UndesirableEffect "Data center projects stall or are withdrawn before approval";
edge ie1 -> d1p
edge ie1 -> ie2
edge ie2 -> ie3
edge ie3 -> ie4
edge ie4 -> ie16
edge ie16 -> ude2

# --- Second branch from D': grooming + apathy exploitation ---
node ie5: IntermediateEffect "Directors have gotten really good at grooming city/county leaders";
node ie6: IntermediateEffect "City/county leaders often feel obligated to be friendly to directors";
node ie7: IntermediateEffect "Directors have played on citizen apathy (people are busy, not enough time to care)";
node ie8: IntermediateEffect "No one shows up to city/county meetings";
edge d1p -> ie5
edge d1p -> ie7
edge ie5 -> ie6
edge ie8 -> ie7

# --- AND-junctor: friendly leaders + no attendance -> less scrutiny ---
node ie9: IntermediateEffect "Projects face less public scrutiny";
edge ie6 -> ie9
edge ie8 -> ie9

# --- The "But" pivot: anger breaks as harms mount (ANGER arms the spine) ---
node ie10: IntermediateEffect "Rising public mistrust of data center developers";
node ie11: IntermediateEffect "Rising consumer electrical rates, blamed on data center demand";
node ie12: IntermediateEffect "Fear of losing jobs";
node ie13: IntermediateEffect "Actual job losses";
node ie14: IntermediateEffect "Massive noisy data centers featured on nightly news";
node ie15: IntermediateEffect "Water/power conservancy promises perceived as lies by elites for profit";
edge ie9 -> ie10
edge ie9 -> ie11
edge ie9 -> ie12
edge ie9 -> ie13
edge ie9 -> ie14
edge ie9 -> ie15
edge ie15 -> ie10

# --- Compounding: actual losses make fear worse ---
edge ie13 -> ie12

# --- Harms feed into anger ---
edge ie10 -> ie4
edge ie11 -> ie4
edge ie12 -> ie4
edge ie14 -> ie4

# --- Additional causes of the UDE (OR branches — each stalls projects alone) ---
# CLR Level III: Cause Insufficiency. Public distrust is NOT the only reason
# projects stall. These are independent roots; any one is sufficient.
node ie17: IntermediateEffect "Local permitting timelines stretch past project financing windows";
node ie18: IntermediateEffect "Utilities cannot commit interconnection capacity to new load";
node ie19: IntermediateEffect "Cost of capital and equipment outpaces projected project returns";

# --- Additional causes: physical constraints + speculative pipeline ---
# ie26 is the PARENT of ie18: speculative queue requests consume interconnection
# study capacity, which is why utilities cannot commit. It also stalls projects
# directly (sites that were never viable).
node ie25: IntermediateEffect "Long-lead electrical equipment is unavailable within project timelines";
node ie26: IntermediateEffect "Speculative projects enter the pipeline without secured power or water";
node ie27: IntermediateEffect "Water availability limits cooling capacity at proposed sites";
edge ie17 -> ude2
edge ie18 -> ude2
edge ie19 -> ude2
edge ie25 -> ude2
edge ie26 -> ude2
edge ie27 -> ude2
edge ie26 -> ie18

# --- Citizens organize opposition (anger becomes political action) ---
# Hangs off ie4: the feeling is already modeled there; these are the ACTIONS.
# Three fronts are OR — any one alone can stop a project.
node ie20: IntermediateEffect "Citizen opposition groups form against local data center projects";
node ie21: IntermediateEffect "Local governments refuse data center approvals";
node ie22: IntermediateEffect "Citizens contest land zoning and annexation for data centers";
node ie23: IntermediateEffect "Citizens contest power rates and interconnection for data centers";
node ie24: IntermediateEffect "Citizens demand transparency on data center operations";
edge ie4 -> ie20
edge ie20 -> ie22
edge ie20 -> ie23
edge ie20 -> ie24
edge ie22 -> ie21
edge ie23 -> ie21
edge ie24 -> ie21
edge ie21 -> ude2

# --- Reinforcing loop 2: pressure feeds back to manipulation ---
# ponytail: reinforcing loop — pressure -> more manipulation
edge ie1 -> d1p

# TODO: what causes ie13 (actual job losses)? Needs a cause entity.
"""

case TOC.list_diagrams() |> Enum.find(&(&1.name == "Cloud 1: Trust vs Speed")) do
  nil ->
    case TOC.create_diagram(%{name: "Cloud 1: Trust vs Speed", dsl: dsl}) do
      {:ok, d} -> IO.puts("created diagram #{d.id}")
      {:error, e} -> IO.inspect(e.errors)
    end

  d ->
    case TOC.update_diagram(d, %{dsl: dsl}) do
      {:ok, u} -> IO.puts("updated diagram #{u.id}")
      {:error, e} -> IO.inspect(e.errors)
    end
end
