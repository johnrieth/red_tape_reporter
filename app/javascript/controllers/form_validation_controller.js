import { Controller } from "@hotwired/stimulus"

// Client-side form validation controller
// Provides real-time validation feedback and character counters
export default class extends Controller {
  static targets = ["field", "submit"]
  static values = {
    minLength: Object,
    maxLength: Object
  }

  connect() {
    // Add validation listeners to all field targets
    this.fieldTargets.forEach(field => {
      field.addEventListener("blur", () => this.validateField(field))
      field.addEventListener("input", () => this.clearError(field))

      // Add character counter if field has maxlength
      if (field.hasAttribute("maxlength") && (field.tagName === "TEXTAREA" || field.type === "text")) {
        this.addCharacterCounter(field)
      }
    })

    // Validate on form submit
    this.element.addEventListener("submit", (event) => {
      if (!this.validateForm()) {
        event.preventDefault()
        this.focusFirstError()
      }
    })
  }

  validateForm() {
    let isValid = true

    this.fieldTargets.forEach(field => {
      if (!this.validateField(field)) {
        isValid = false
      }
    })

    return isValid
  }

  validateField(field) {
    // Skip validation for optional fields that are empty
    if (!field.required && field.value.trim() === "") {
      return true
    }

    let isValid = true
    let errorMessage = ""

    // Required field validation
    if (field.required && field.value.trim() === "") {
      isValid = false
      errorMessage = "This field is required"
    }
    // Email validation
    else if (field.type === "email" && field.value.trim() !== "") {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      if (!emailRegex.test(field.value)) {
        isValid = false
        errorMessage = "Please enter a valid email address"
      }
    }
    // Select field validation
    else if (field.tagName === "SELECT" && field.required) {
      if (field.value === "" || field.value === null) {
        isValid = false
        errorMessage = "Please select an option"
      }
    }
    // Minimum length validation
    else if (field.hasAttribute("data-min-length")) {
      const minLength = parseInt(field.getAttribute("data-min-length"))
      const currentLength = field.value.trim().length

      if (currentLength > 0 && currentLength < minLength) {
        isValid = false
        errorMessage = `Please enter at least ${minLength} characters (currently ${currentLength})`
      } else if (field.required && currentLength === 0) {
        isValid = false
        errorMessage = "This field is required"
      }
    }

    if (!isValid) {
      this.showError(field, errorMessage)
    } else {
      this.clearError(field)
    }

    return isValid
  }

  showError(field, message) {
    // Remove existing error if present
    this.clearError(field)

    // Add error class to field
    field.classList.add("field-error")
    field.setAttribute("aria-invalid", "true")

    // Create and insert error message
    const errorDiv = document.createElement("div")
    errorDiv.className = "field-error-message"
    errorDiv.setAttribute("role", "alert")
    errorDiv.textContent = message

    const errorId = `${field.id || field.name}_error`
    errorDiv.id = errorId
    field.setAttribute("aria-describedby", errorId)

    field.parentNode.insertBefore(errorDiv, field.nextSibling)
  }

  clearError(field) {
    field.classList.remove("field-error")
    field.removeAttribute("aria-invalid")

    // Remove error message if it exists
    const nextElement = field.nextSibling
    if (nextElement && nextElement.classList?.contains("field-error-message")) {
      nextElement.remove()
    }
  }

  addCharacterCounter(field) {
    const maxLength = parseInt(field.getAttribute("maxlength"))
    const currentLength = field.value.length

    // Create counter element
    const counter = document.createElement("div")
    counter.className = "character-counter"
    counter.setAttribute("aria-live", "polite")
    counter.textContent = `${currentLength} / ${maxLength} characters`

    // Insert after help text if it exists, otherwise after field
    const helpText = field.parentNode.querySelector(".help-text")
    if (helpText) {
      helpText.parentNode.insertBefore(counter, helpText.nextSibling)
    } else {
      field.parentNode.appendChild(counter)
    }

    // Update counter on input
    field.addEventListener("input", () => {
      const current = field.value.length
      counter.textContent = `${current} / ${maxLength} characters`

      // Add warning class when approaching limit
      if (current > maxLength * 0.9) {
        counter.classList.add("character-counter--warning")
      } else {
        counter.classList.remove("character-counter--warning")
      }
    })
  }

  focusFirstError() {
    const firstError = this.element.querySelector(".field-error")
    if (firstError) {
      firstError.focus()
      firstError.scrollIntoView({ behavior: "smooth", block: "center" })
    }
  }
}
