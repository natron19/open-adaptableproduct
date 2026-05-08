import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values  = { product: String, generated: String }
  static targets = ["row"]

  download() {
    const lines = []

    lines.push(`# Assumption Matrix: ${this.productValue}`)
    lines.push(``)
    lines.push(`**Generated:** ${this.generatedValue}`)
    lines.push(``)
    lines.push(`---`)
    lines.push(``)

    this.rowTargets.forEach((row, i) => {
      const { statement, confidenceAi, confidenceUser, risk, category, experiment } = row.dataset
      const yourConf = confidenceUser && confidenceUser !== "0" ? `${confidenceUser}/5` : "—"

      lines.push(`### ${i + 1}. [${category} / ${risk} risk]`)
      lines.push(`**Assumption:** ${statement}`)
      lines.push(``)
      lines.push(`**AI Confidence:** ${confidenceAi}/5 &nbsp; **Your Confidence:** ${yourConf}`)
      lines.push(``)
      lines.push(`**Experiment:** ${experiment}`)
      lines.push(``)
      lines.push(`---`)
      lines.push(``)
    })

    const slug = this.productValue.toLowerCase().replace(/\s+/g, "-").replace(/[^a-z0-9-]/g, "")
    const filename = `${slug}-assumption-matrix.md`
    const blob = new Blob([lines.join("\n")], { type: "text/markdown;charset=utf-8" })
    const url  = URL.createObjectURL(blob)
    const a    = document.createElement("a")
    a.href     = url
    a.download = filename
    a.click()
    URL.revokeObjectURL(url)
  }
}
