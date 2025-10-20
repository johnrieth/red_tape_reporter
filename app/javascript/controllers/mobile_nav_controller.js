import { Controller } from "@hotwired/stimulus"

// Mobile navigation toggle controller
// Handles hamburger menu open/close on mobile devices
export default class extends Controller {
  static targets = ["menu", "hamburger"]

  connect() {
    // Close menu when clicking outside
    this.boundCloseOnOutsideClick = this.closeOnOutsideClick.bind(this)

    // Close menu on escape key
    this.boundCloseOnEscape = this.closeOnEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnOutsideClick)
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }

  toggle(event) {
    event.stopPropagation()
    const isOpen = this.menuTarget.classList.contains("nav-links--open")

    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.add("nav-links--open")
    this.hamburgerTarget.classList.add("hamburger--active")
    this.hamburgerTarget.setAttribute("aria-expanded", "true")

    // Add listeners when menu is open
    document.addEventListener("click", this.boundCloseOnOutsideClick)
    document.addEventListener("keydown", this.boundCloseOnEscape)

    // Prevent body scroll on mobile when menu is open
    document.body.style.overflow = "hidden"
  }

  close() {
    this.menuTarget.classList.remove("nav-links--open")
    this.hamburgerTarget.classList.remove("hamburger--active")
    this.hamburgerTarget.setAttribute("aria-expanded", "false")

    // Remove listeners when menu is closed
    document.removeEventListener("click", this.boundCloseOnOutsideClick)
    document.removeEventListener("keydown", this.boundCloseOnEscape)

    // Restore body scroll
    document.body.style.overflow = ""
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  // Close menu when a link is clicked (better UX on mobile)
  closeOnLinkClick() {
    this.close()
  }
}
