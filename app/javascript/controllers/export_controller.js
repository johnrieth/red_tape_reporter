import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startDate", "endDate"]

  exportCsv(event) {
    event.preventDefault()
    this.export("csv")
  }

  exportPdf(event) {
    event.preventDefault()
    this.export("pdf")
  }

  export(format) {
    const startDate = this.startDateTarget.value
    const endDate = this.endDateTarget.value

    if (!startDate || !endDate) {
      alert("Please select both start and end dates")
      return
    }

    const url = `/admin/reports/export.${format}?start_date=${startDate}&end_date=${endDate}`
    window.location.href = url
  }
}
