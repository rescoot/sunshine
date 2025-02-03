import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.handleIncomingMessages()
  }

  handleIncomingMessages() {
    // Listen for messages coming through ActionCable
    document.addEventListener("turbo:before-stream-render", (event) => {
      const scooterId = event.target.getAttribute('data-scooter')
      if (!scooterId) return

      const message = JSON.parse(event.target.textContent)
      const outputDiv = this.findLatestOutputDiv()
      
      if (!outputDiv) return

      switch(message.type) {
        case "shell_output":
          this.handleShellOutput(outputDiv, message)
          break
        case "shell_complete":
          this.handleShellComplete(outputDiv, message)
          break
        case "redis_result":
          this.handleRedisResult(outputDiv, message)
          break
      }

      // Prevent default Turbo handling since we're handling it ourselves
      event.preventDefault()
    })
  }

  findLatestOutputDiv() {
    const outputs = this.element.querySelectorAll('.command-output')
    return outputs[outputs.length - 1]
  }

  handleShellOutput(outputDiv, message) {
    if (message.done) return // Wait for shell_complete

    const line = document.createElement('div')
    line.className = message.output_type === 'stderr' ? 'text-red-400' : 'text-gray-300'
    line.textContent = message.output
    
    // Replace loading message if it's there
    if (outputDiv.firstChild.classList.contains('animate-pulse')) {
      outputDiv.innerHTML = ''
    }
    
    outputDiv.appendChild(line)
  }

  handleShellComplete(outputDiv, message) {
    outputDiv.innerHTML = ''
    
    if (message.stdout) {
      const stdout = document.createElement('pre')
      stdout.className = 'text-gray-300 whitespace-pre-wrap'
      stdout.textContent = message.stdout
      outputDiv.appendChild(stdout)
    }

    if (message.stderr) {
      const stderr = document.createElement('pre')
      stderr.className = 'text-red-400 whitespace-pre-wrap'
      stderr.textContent = message.stderr
      outputDiv.appendChild(stderr)
    }

    const exitCode = document.createElement('div')
    exitCode.className = message.exit_code === 0 ? 'text-green-400' : 'text-red-400'
    exitCode.textContent = `Exit code: ${message.exit_code}`
    outputDiv.appendChild(exitCode)
  }

  handleRedisResult(outputDiv, message) {
    outputDiv.innerHTML = ''
    
    const result = document.createElement('pre')
    result.className = 'text-gray-300 whitespace-pre-wrap'
    result.textContent = JSON.stringify(message.result, null, 2)
    outputDiv.appendChild(result)
  }
}