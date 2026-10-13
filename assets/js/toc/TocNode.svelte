<script>
  // assets/js/toc/TocNode.svelte
  // Custom Svelte Flow node: label text + a small corner badge (top-left) that
  // never overlaps the text. The badge is absolutely positioned in its own
  // corner; the label starts after it.
  export let data;
</script>

<div class="toc-node" style="border-color: {data.stroke}; background: {data.fill}">
  {#if data.badge}
    <span class="badge" style="background: {data.stroke}">{data.badge}</span>
  {/if}
  <span class="label">{data.label}</span>
</div>

<style>
  .toc-node {
    position: relative;
    border: 2px solid;
    border-radius: 6px;
    padding: 8px 10px;
    min-width: 180px;
    max-width: 260px;
    min-height: 40px;
    font-size: 12px;
    line-height: 1.3;
  }
  .badge {
    position: absolute;
    top: 4px;
    left: 4px;
    padding: 1px 5px;
    border-radius: 3px;
    color: #fff;
    font-size: 10px;
    font-family: ui-monospace, monospace;
    font-weight: 600;
    letter-spacing: 0.02em;
  }
  .label {
    display: block;
    padding-left: 0;
    color: #1e1e1e;
  }
</style>
