<script>
  // assets/js/toc/TocNode.svelte
  // Custom Svelte Flow node — RUNES MODE (Svelte 5). A narrow, readable card:
  // the badge sits in its own top-left corner, the label starts after it so
  // they never overlap. Label color is set inline so SvelteFlow's dark-mode
  // default can't override it.
  let { data } = $props();
</script>

<div class="toc-node" style="border-color: {data.stroke}; background: {data.fill}">
  {#if data.badge}
    <span class="badge" style="background: {data.stroke}">{data.badge}</span>
  {/if}
  <span class="label" style="color: #1e1e1e">{data.label}</span>
</div>

<style>
  .toc-node {
    position: relative;
    border: 2px solid;
    border-radius: 6px;
    padding: 6px 10px 6px 34px; /* left padding clears the corner badge */
    width: 200px;
    min-height: 34px;
    font-size: 12px;
    line-height: 1.35;
    box-sizing: border-box;
  }
  .badge {
    position: absolute;
    top: 5px;
    left: 5px;
    padding: 1px 5px;
    border-radius: 3px;
    color: #fff;
    font-size: 10px;
    font-family: ui-monospace, monospace;
    font-weight: 600;
    letter-spacing: 0.02em;
    white-space: nowrap;
  }
  .label {
    display: block;
    color: #1e1e1e !important;
    word-wrap: break-word;
  }
</style>
