import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  rate(event) {
    const rating = parseInt(event.currentTarget.dataset.value)
    this.inputTarget.value = rating
    this.renderDots(rating)
    this.element.requestSubmit()
  }

  preview(event) {
    const rating = parseInt(event.currentTarget.dataset.value)
    this.renderDots(rating)
  }

  resetPreview() {
    const current = parseInt(this.inputTarget.value) || 0
    this.renderDots(current)
  }

  renderDots(upTo) {
    this.element.querySelectorAll(".confidence-dot").forEach((dot, i) => {
      dot.classList.toggle("filled", i < upTo)
    })
  }
}
