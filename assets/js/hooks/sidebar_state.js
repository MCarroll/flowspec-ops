/**
 * SidebarState Hook - Handles desktop sidebar hide/expand state.
 *
 * Persists preference in localStorage so the menu state remains stable
 * across LiveView navigations and page reloads.
 */
const SIDEBAR_STATE_KEY = "desktop_sidebar_state"

const SidebarState = {
  mounted() {
    this.handleToggle = () => {
      this.isHidden = !this.isHidden
      this.persistState()
      this.applyState()
    }

    this.cacheElements()
    this.isHidden = localStorage.getItem(SIDEBAR_STATE_KEY) === "hidden"
    this.bindToggleButtons()
    this.applyState()
  },

  updated() {
    this.unbindToggleButtons()
    this.cacheElements()
    this.bindToggleButtons()
    this.applyState()
  },

  destroyed() {
    this.unbindToggleButtons()
  },

  cacheElements() {
    this.desktopSidebar = this.el.querySelector("#desktop-sidebar")
    this.dashboardContent = this.el.querySelector("#dashboard-content")
    this.toggleButtons = Array.from(this.el.querySelectorAll("[data-sidebar-toggle]"))
    this.toggleIcons = Array.from(this.el.querySelectorAll("[data-sidebar-icon=\"toggle\"]"))
  },

  bindToggleButtons() {
    this.toggleButtons.forEach((button) => button.addEventListener("click", this.handleToggle))
  },

  unbindToggleButtons() {
    this.toggleButtons.forEach((button) => button.removeEventListener("click", this.handleToggle))
  },

  persistState() {
    localStorage.setItem(SIDEBAR_STATE_KEY, this.isHidden ? "hidden" : "expanded")
  },

  applyState() {
    if (!this.desktopSidebar || !this.dashboardContent) return

    this.desktopSidebar.classList.toggle("translate-x-0", !this.isHidden)
    this.desktopSidebar.classList.toggle("-translate-x-full", this.isHidden)
    this.dashboardContent.classList.toggle("pl-0", this.isHidden)
    this.dashboardContent.classList.toggle("pl-[10.5rem]", !this.isHidden)
    this.toggleIcons.forEach((icon) => icon.classList.toggle("rotate-180", this.isHidden))

    this.toggleButtons.forEach((button) => {
      button.setAttribute("aria-expanded", String(!this.isHidden))
      button.setAttribute("title", this.isHidden ? "Expand menu" : "Hide menu")

      const srLabel = button.querySelector("[data-sidebar-toggle-label]")
      if (srLabel) {
        srLabel.textContent = this.isHidden ? "Expand menu" : "Hide menu"
      }
    })
  }
}

export default SidebarState
