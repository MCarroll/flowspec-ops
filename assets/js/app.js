// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Hooks
import SidebarState from "./hooks/sidebar_state"
import StepCycleCalc from "./hooks/step_cycle_calc"
import TabSubmitLast from "./hooks/tab_submit_last"
import NetScroll from "./hooks/net_scroll"
import AutoSelect from "./hooks/auto_select"
import TocGraph from "./hooks/toc_graph"

let Hooks = {
  SidebarState: SidebarState,
  StepCycleCalc: StepCycleCalc,
  TabSubmitLast: TabSubmitLast,
  NetScroll: NetScroll,
  AutoSelect: AutoSelect,
  TocGraph: TocGraph
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

window.addEventListener("phx:scroll_net", (event) => {
  const container = document.getElementById("net-scroll")
  if (!container) return
  const align = event.detail.align || "left"
  if (align === "left") {
    container.scrollTo({ left: 0, behavior: "smooth" })
  } else if (align === "right") {
    container.scrollTo({ left: container.scrollWidth, behavior: "smooth" })
  } else {
    container.scrollTo({ left: (container.scrollWidth - container.clientWidth) / 2, behavior: "smooth" })
  }
})

// Scroll to a specific node card when spine segment is clicked.
// The whole net (#net-scroll) scrolls as one unit so all lines move together.
window.addEventListener("phx:scroll_to_node", (event) => {
  const nodeId = event.detail.node_id
  const card = document.querySelector(`[data-node-id="${nodeId}"]`)
  if (!card) return
  // The net container holds every line; scroll it so the card centers.
  const container = document.getElementById("net-scroll") || card.closest(".overflow-x-auto")
  if (!container) return
  const cardRect = card.getBoundingClientRect()
  const containerRect = container.getBoundingClientRect()
  const scrollLeft =
    container.scrollLeft +
    (cardRect.left - containerRect.left) -
    (containerRect.width / 2) +
    (cardRect.width / 2)
  container.scrollTo({ left: scrollLeft, behavior: "smooth" })
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

