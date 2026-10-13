// assets/js/hooks/toc_graph.js
// LiveView hook that mounts the Svelte Flow TOC canvas and wires the round-trip:
//   - user drags/edits -> pushEvent("graph_changed", {graph}) -> LiveView persists
//   - agent/LiveView updates -> handleEvent("graph_update") -> re-render canvas
import TocGraphApp from "../toc/TocGraph.svelte";

let TocGraph = {
  mounted() {
    const el = this.el;
    const initial = JSON.parse(el.dataset.graph || "{}");

    this.app = new TocGraphApp({
      target: el,
      props: { graph: initial },
    });

    // canvas -> server
    this.app.$on("graph_changed", (e) => {
      this.pushEvent("graph_changed", { graph: e.detail });
    });

    // server -> canvas (agent edits, PubSub broadcast)
    this.handleEvent("graph_update", (payload) => {
      this.app.$set({ graph: payload.graph });
    });
  },
  destroyed() {
    if (this.app) this.app.$destroy();
  },
};

export default TocGraph;
