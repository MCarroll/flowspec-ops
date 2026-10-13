<script>
  // assets/js/toc/TocGraph.svelte
  // Svelte Flow canvas for TOC trees — RUNES MODE (Svelte 5).
  // SvelteFlow's nodes/edges are $bindable, so we hold them as $state and use
  // bind:nodes / bind:edges. We sync them from the store reactively.
  import { SvelteFlow, Background } from "@xyflow/svelte";
  import "@xyflow/svelte/dist/style.css";
  import TocNode from "./TocNode.svelte";
  import { graphStore } from "./graph_store.js";

  const nodeTypes = { tocNode: TocNode };

  // Callback prop (runes): the hook passes a function to push changes to server.
  let { onChange = () => {} } = $props();

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

  // SvelteFlow owns these via bind: — $state, not $derived.
  let flowNodes = $state([]);
  let flowEdges = $state([]);

  // Sync from the store whenever it changes.
  $effect(() => {
    const g = $graphStore;
    flowNodes = (g.nodes || []).map((n) => {
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
    flowEdges = (g.edges || []).map((e) => ({
      id: e.id || `${e.source}-${e.target}`,
      source: e.source,
      target: e.target,
      animated: false,
    }));
  });

  // Push position changes back through onChange (-> hook -> server).
  function onNodesChange(changes) {
    const moved = changes.filter((c) => c.type === "position");
    if (moved.length) {
      const g = $graphStore;
      const updated = (g.nodes || []).map((n) => {
        const m = moved.find((c) => c.id === n.id);
        return m ? { ...n, x: m.position.x, y: m.position.y } : n;
      });
      onChange({ nodes: updated, edges: g.edges || [] });
    }
  }
</script>

<div class="toc-canvas" style="width: 100%; height: 100%">
  <SvelteFlow
      bind:nodes={flowNodes}
      bind:edges={flowEdges}
      {nodeTypes}
      on:nodesChange={onNodesChange}
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
