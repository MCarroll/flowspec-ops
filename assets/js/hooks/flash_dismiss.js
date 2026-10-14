// Auto-dismiss flash toasts after 2 seconds by triggering the same click
// handler the close button uses (lv:clear-flash + hide transition).
const FlashDismiss = {
  mounted() {
    this.timer = setTimeout(() => {
      // the flash div itself has the phx-click that clears it
      this.el.querySelector("[phx-click]")?.click() || this.el.click()
    }, 2000)
  },
  destroyed() {
    clearTimeout(this.timer)
  }
}

export default FlashDismiss
