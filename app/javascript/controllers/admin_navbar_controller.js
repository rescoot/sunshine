import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["navbar"]
  
  toggle() {
    this.navbarTarget.classList.toggle("hidden")
  }
}
