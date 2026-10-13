<script>
  // assets/js/toc/TocGraph.svelte
  // Svelte Flow canvas for TOC trees. Renders entity nodes with a corner badge
  // (A/B/C/D/D'/IE/IO/UDE/INJ) that never overlaps the label text.
  import { SvelteFlow, Background } from "@xyflow/svelte";
  import "@xyflow/svelte/dist/style.css";
  import TocNode from "./TocNode.svelte";
  import { createEventDispatcher } from "svelte";

  const dispatch = createEventDispatcher();
  const nodeTypes = { tocNode: TocNode };

  export let graph = { nodes: [], edges: [] };

  // Map a node's class to its badge prefix + colors.
  const BADGE = {
    "Common Objective": { prefix: "A", fill: "#b2f2bb", stroke: "#2f9e44" },
    Need: { prefix: "B", fill: "#ffe8cc", stroke: "#e8590c" },
    Want: { prefix: "D", fill: "#fcc2d7", stroke: "#d6336c" },
    Conflict: { prefix: "", fill: "#ffc9c9", stroke: "#c92a2a" },
    "Intermediate Effect": { prefix: "IE", fill: "#ffe3e3", stroke: "#e03131" },
    "Intermediate Objective": { prefix: "IO", fill: "#ffe3e3", stroke: "#e03131" },
    UDE: { prefix: "UDE", fill: "#fff0f0", stroke: "#e03131" },
    Injection: { prefix: "INJ", fill: "#d0ebff", stroke: "#1971c2" },
  };

  // Build Svelte Flow nodes from the stored graph. Each node carries its badge
  // in `data`; the custom node component renders it in the top-left corner.
  $: flowNodes = (graph.nodes || []).map((n) => {
    const badge = BADGE[n.class] || { prefix: "", fill: "#f1f3f5", stroke: "#495057" };
    return {
      id: n.id,
      position: { x: n.x || 0, y: n.y || 0 },
      data: {
        label: n.label || n.title || n.id,
        badge: badge.prefix ? `${badge.prefix}${n.number || ""}` : "",
        fill: badge.fill,
        stroke: badge.stroke,
      },
      type: "tocNode",
    };
  });

  $: flowEdges = (graph.edges || []).map((e) => ({
    id: e.id || `${e.source}-${e.target}`,
    source: e.source,
    target: e.target,
    animated: false,
  }));

  // Push changes back to the LiveView hook.
  function onNodesChange(changes) {
    // position changes -> emit full graph
    const moved = changes.filter((c) => c.type === "position");
    if (moved.length) {
      const updated = (graph.nodes || []).map((n) => {
        const m = moved.find((c) => c.id === n.id);
        return m ? { ...n, x: m.position.x, y: m.position.y } : n;
      });
      dispatch("graph_changed", { nodes: updated, edges: graph.edges || [] });
    }
  }
</script>

<div class="toc-canvas" style="width: 100%; height: 100%">
  <SvelteFlow
    {flowNodes}
    {flowEdges}
    {nodeTypes}
    on:nodesChange={onNodesChange}
    fitView
    nodesDraggable
    nodesConnectable={false}
  >
    <Background />
  </SvelteFlow>
</div>

<style>
  .toc-canvas :global(.react-flow__node) {
    font-size: 12px;
  }
</style>
