// NetScroll: scroll the whole project net container (id="net-scroll").
// Left/Center/Right buttons push a "scroll_net" event; we translate that
// into a scroll of the whole grid so every line moves together.
const NetScroll = {
  mounted() {
    this.handleScrollNet = (event) => {
      const container = this.el
      if (!container) return
      const align = event.detail.align || "left"
      if (align === "left") {
        container.scrollTo({left: 0, behavior: "smooth"})
      } else if (align === "right") {
        container.scrollTo({left: container.scrollWidth, behavior: "smooth"})
      } else {
        // center
        container.scrollTo({left: (container.scrollWidth - container.clientWidth) / 2, behavior: "smooth"})
      }
    }
    this.el.addEventListener("phx:scroll_net", this.handleScrollNet)
  },
  destroyed() {
    this.el.removeEventListener("phx:scroll_net", this.handleScrollNet)
  }
}

export default NetScroll
