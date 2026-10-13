// assets/js/hooks/toc_graph.js
// LiveView hook that mounts the Svelte Flow TOC canvas and wires the round-trip.
// Uses Svelte 5: mount() + a shared store (NOT `new Component()` / $on / $set,
// which are gone in Svelte 5).
import { mount } from "svelte";
import TocGraphApp from "../toc/TocGraph.svelte";
import { graphStore } from "../toc/graph_store.js";

let TocGraph = {
  mounted() {
    const el = this.el;
    const initial = JSON.parse(el.dataset.graph || "{}");
    graphStore.set(initial);

    this.app = mount(TocGraphApp, {
      target: el,
      props: {
        onChange: (graph) => {
          graphStore.set(graph);
          this.pushEvent("graph_changed", { graph });
        },
      },
    });
  },
  updated() {
    // Server re-rendered the div; re-read data-graph (agent edits / broadcast).
    const el = this.el;
    if (el.dataset.graph) {
      graphStore.set(JSON.parse(el.dataset.graph));
    }
  },
  destroyed() {
    if (this.app) this.app.$destroy?.();
  },
};

export default TocGraph;
