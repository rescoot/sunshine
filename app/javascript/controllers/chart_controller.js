import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  static targets = ["canvas"]
  static values = { 
    data: Object,
    type: String,
    options: Object
  }
  
  connect() {
    if (!this.hasCanvasTarget) return
    
    this.createChart()
  }
  
  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }
  
  createChart() {
    const ctx = this.canvasTarget.getContext('2d')
    
    this.chart = new Chart(ctx, {
      type: this.typeValue || 'line',
      data: this.dataValue || { datasets: [] },
      options: this.optionsValue || {}
    })
  }
  
  // This method can be called from other controllers or Turbo events
  updateData(data) {
    if (!this.chart) return
    
    this.chart.data = data
    this.chart.update()
  }
  
  // This can be triggered by a button or other event
  downloadCSV(event) {
    event.preventDefault()
    
    if (!this.chart || !this.chart.data) return
    
    const labels = this.chart.data.labels || []
    const datasets = this.chart.data.datasets || []
    
    // Create CSV header row
    let csvContent = "data:text/csv;charset=utf-8,"
    let header = ["Date"]
    
    // Add dataset names to header
    datasets.forEach(dataset => {
      header.push(dataset.label || "Dataset")
    })
    
    csvContent += header.join(",") + "\r\n"
    
    // Add data rows
    labels.forEach((label, i) => {
      let row = [label]
      
      datasets.forEach(dataset => {
        row.push(dataset.data[i] || "")
      })
      
      csvContent += row.join(",") + "\r\n"
    })
    
    // Create download link
    const encodedUri = encodeURI(csvContent)
    const link = document.createElement("a")
    link.setAttribute("href", encodedUri)
    link.setAttribute("download", "chart-data.csv")
    document.body.appendChild(link)
    
    // Trigger download and clean up
    link.click()
    document.body.removeChild(link)
  }
}
