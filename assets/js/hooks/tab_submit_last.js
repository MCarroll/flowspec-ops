// Tab (or Enter) on the last visible field of an add-row submits the form.
const TabSubmitLast = {
  mounted() {
    this.el.addEventListener("keydown", (e) => {
      if (e.key !== "Tab" || e.shiftKey) return
      const fields = [...this.el.querySelectorAll("input:not([type=hidden]), select, textarea")].filter(
        (el) => !el.disabled && el.offsetParent !== null
      )
      if (!fields.length) return
      const last = fields[fields.length - 1]
      if (document.activeElement === last) {
        e.preventDefault()
        // prefer form attribute
        const formId = last.getAttribute("form")
        const form = formId ? document.getElementById(formId) : this.el.closest("form") || this.el.querySelector("form")
        if (form) {
          if (typeof form.requestSubmit === "function") form.requestSubmit()
          else form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }))
        }
      }
    })
  }
}
export default TabSubmitLast
