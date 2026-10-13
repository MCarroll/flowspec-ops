// assets/js/hooks/toc_zoom.js
// Wheel-zoom for the TOC SVG graph. The SVG is rendered at a fixed base pixel
// size; this hook scales its rendered width/height on wheel, so the overflow
// container's scroll bounds grow with the zoom (scroll left/right as the graph
// grows). Ctrl+wheel zooms; plain wheel scrolls the container natively.
let TocZoom = {
  mounted() {
    this.el.addEventListener("wheel", (e) => {
      if (!e.ctrlKey) return; // let plain wheel scroll the container
      e.preventDefault();
      const svg = this.el.querySelector("svg");
      if (!svg) return;
      const baseW = parseFloat(svg.dataset.baseW);
      const baseH = parseFloat(svg.dataset.baseH);
      if (!baseW || !baseH) return;
      const factor = e.deltaY < 0 ? 1.1 : 0.9;
      const w = Math.min(8000, Math.max(200, parseFloat(svg.style.width || baseW) * factor));
      const h = (w / baseW) * baseH;
      svg.style.width = w + "px";
      svg.style.height = h + "px";
    });
  },
};

export default TocZoom;
