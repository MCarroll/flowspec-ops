// assets/js/toc/graph_store.js
// Svelte 5 shared store for the TOC graph JSON. The hook and the SvelteFlow
// component both read/write this — the store is the single client-side source
// of truth, and the server (Ecto) is the durable source of truth.
import { writable } from "svelte/store";

export const graphStore = writable({ nodes: [], edges: [] });
