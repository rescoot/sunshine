import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["navbar", "mobileMenu"]
  
  toggle() {
    this.navbarTarget.classList.toggle("hidden")
  }

  toggleMobile() {
    this.mobileMenuTarget.classList.toggle("hidden")
  }
}
