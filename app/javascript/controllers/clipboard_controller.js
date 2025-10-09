import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "url", "button", "feedback" ]
  
  copy() {
    const textToCopy = this.urlTarget.textContent;
    
    navigator.clipboard.writeText(textToCopy).then(() => {
      this.showFeedback();
    }).catch(err => {
      // Fallback for older browsers
      const textArea = document.createElement("textarea");
      textArea.value = textToCopy;
      document.body.appendChild(textArea);
      textArea.focus();
      textArea.select();
      
      try {
        document.execCommand('copy');
        this.showFeedback();
      } catch (err) {
        console.error('Failed to copy: ', err);
      }
      
      document.body.removeChild(textArea);
    });
  }
  
  showFeedback() {
    const originalText = this.buttonTarget.textContent;
    this.buttonTarget.textContent = "Copied!";
    this.buttonTarget.style.background = "#28a745";
    
    setTimeout(() => {
      this.buttonTarget.textContent = originalText;
      this.buttonTarget.style.background = "";
    }, 2000);
  }
}