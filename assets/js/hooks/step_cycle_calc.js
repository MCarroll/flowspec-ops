// Instant cycle math in the step popup (no round-trip for display).
// Cycle = qty × min/ea (work content time).
// Process time = ceil(cycle / people) when Shared checked; = cycle when Shared unchecked
// (e.g. crane/gang move: one gang does one move, crew size is demand only).
const StepCycleCalc = {
  mounted() {
    this.el.addEventListener("input", () => this.recalc())
    this.el.addEventListener("change", () => this.recalc())
    this.recalc()
  },

  updated() {
    this.recalc()
  },

  recalc() {
    const qty = this.num(this.el.querySelector("[data-cycle-qty]"))
    const each = this.num(this.el.querySelector("[data-cycle-each]"))
    const people = this.num(this.el.querySelector("[data-cycle-people]"))
    const sharedEl = this.el.querySelector("[data-cycle-shared]")

    const cycleEl = this.el.querySelector("[data-cycle-out]")
    const processEl = this.el.querySelector("[data-process-out]")

    let cycle = null
    if (qty != null && each != null) cycle = qty * each

    if (cycleEl) cycleEl.textContent = cycle != null ? `${cycle}m` : "—"

    // Process time: shared (default true) → ceil(cycle/people); not shared → cycle.
    const isShared = sharedEl ? sharedEl.checked : true
    let process = null
    if (cycle != null) {
      if (isShared && people != null && people > 0) {
        process = Math.ceil(cycle / people)
      } else {
        process = cycle
      }
    }

    if (processEl) processEl.textContent = process != null ? `${process}m` : "—"
  },

  num(input) {
    if (!input) return null
    const v = parseInt(String(input.value || "").trim(), 10)
    return Number.isFinite(v) && v > 0 ? v : null
  }
}

export default StepCycleCalc
