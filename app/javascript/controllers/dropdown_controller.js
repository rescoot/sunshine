import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "chevron"]

  toggle(event) {
    event.stopPropagation()
    const isHidden = this.menuTarget.classList.contains("hidden")
    
    // If we're opening the dropdown, close all other dropdowns first
    if (isHidden) {
      this.closeAllDropdowns()
    }
    
    this.menuTarget.classList.toggle("hidden")
    
    // Set high z-index when visible to ensure it appears above other elements like maps
    if (!this.menuTarget.classList.contains("hidden")) {
      this.menuTarget.style.zIndex = "50" // High z-index value
    } else {
      this.menuTarget.style.zIndex = ""   // Reset when hidden
    }
    
    // Rotate chevron if it exists
    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle("rotate-180")
    }
    
    // If we're opening the dropdown, dispatch an event to notify other dropdowns
    if (!this.menuTarget.classList.contains("hidden")) {
      const event = new CustomEvent("dropdown:opened", { 
        bubbles: true,
        detail: { id: this.element.id }
      })
      document.dispatchEvent(event)
    }
  }

  connect() {
    this.clickOutsideHandler = this.closeOnClickOutside.bind(this)
    this.dropdownOpenedHandler = this.closeOnOtherDropdownOpened.bind(this)
    
    document.addEventListener("click", this.clickOutsideHandler)
    document.addEventListener("dropdown:opened", this.dropdownOpenedHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.clickOutsideHandler)
    document.removeEventListener("dropdown:opened", this.dropdownOpenedHandler)
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.closeDropdown()
    }
  }
  
  closeOnOtherDropdownOpened(event) {
    // Only close if it's a different dropdown that was opened
    if (event.detail.id !== this.element.id) {
      this.closeDropdown()
    }
  }
  
  closeDropdown() {
    this.menuTarget.classList.add("hidden")
    this.menuTarget.style.zIndex = "" // Reset z-index when closing
    if (this.hasChevronTarget) {
      this.chevronTarget.classList.remove("rotate-180")
    }
  }
  
  closeAllDropdowns() {
    // Find all dropdown menus and close them
    document.querySelectorAll("[data-controller='dropdown']").forEach(dropdown => {
      const controller = this.application.getControllerForElementAndIdentifier(dropdown, "dropdown")
      if (controller && controller !== this) {
        controller.closeDropdown()
      }
    })
  }
}
