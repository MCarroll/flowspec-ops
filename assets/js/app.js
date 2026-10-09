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

let Hooks = {
  SidebarState: SidebarState,
  StepCycleCalc: StepCycleCalc,
  TabSubmitLast: TabSubmitLast
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

// Scroll to a specific node card when spine segment is clicked
window.addEventListener("phx:scroll_to_node", (event) => {
  const nodeId = event.detail.node_id
  const card = document.querySelector(`[data-node-id="${nodeId}"]`)
  if (card) {
    const container = card.closest(".overflow-x-auto")
    if (container) {
      const cardRect = card.getBoundingClientRect()
      const containerRect = container.getBoundingClientRect()
      const scrollLeft = card.offsetLeft - container.offsetLeft - (containerRect.width / 2) + (cardRect.width / 2)
      container.scrollTo({ left: scrollLeft, behavior: "smooth" })
    }
  }
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

