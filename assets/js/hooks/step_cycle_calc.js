// Instant cycle math in the step popup (no round-trip for display).
// Cycle = qty × min/ea (one-person content time).
// After people: wall = ceil(cycle / people). Still not a second "cycle" label.
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

    const cycleEl = this.el.querySelector("[data-cycle-out]")
    const wallEl = this.el.querySelector("[data-wall-out]")

    let cycle = null
    if (qty != null && each != null) cycle = qty * each

    if (cycleEl) cycleEl.textContent = cycle != null ? `${cycle}m` : "—"

    let wall = null
    if (cycle != null && people != null && people > 0) {
      wall = Math.ceil(cycle / people)
    } else if (cycle != null) {
      wall = cycle
    }

    if (wallEl) wallEl.textContent = wall != null ? `${wall}m` : "—"
  },

  num(input) {
    if (!input) return null
    const v = parseInt(String(input.value || "").trim(), 10)
    return Number.isFinite(v) && v > 0 ? v : null
  }
}

export default StepCycleCalc
