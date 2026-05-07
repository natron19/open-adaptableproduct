import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table"]

  sortByLeverage(event) {
    this.setActive(event.currentTarget)
    this.sort((a, b) => parseInt(a.dataset.position) - parseInt(b.dataset.position))
    this.toggleGapColumn(false)
  }

  sortByRisk(event) {
    this.setActive(event.currentTarget)
    const order = { high: 0, medium: 1, low: 2 }
    this.sort((a, b) => order[a.dataset.risk] - order[b.dataset.risk])
    this.toggleGapColumn(false)
  }

  sortByGap(event) {
    this.setActive(event.currentTarget)
    this.sort((a, b) => parseFloat(b.dataset.gap) - parseFloat(a.dataset.gap))
    this.toggleGapColumn(true)
  }

  sort(compareFn) {
    const tbody = this.tableTarget.querySelector("tbody")
    Array.from(tbody.querySelectorAll("tr"))
      .sort(compareFn)
      .forEach(row => tbody.appendChild(row))
  }

  toggleGapColumn(visible) {
    this.element.querySelectorAll(".gap-col").forEach(el => {
      el.classList.toggle("d-none", !visible)
    })
  }

  setActive(btn) {
    this.element.querySelectorAll("[data-action*='matrix-sort']").forEach(b => {
      b.classList.remove("active")
    })
    btn.classList.add("active")
  }
}
