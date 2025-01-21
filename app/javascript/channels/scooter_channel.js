import consumer from "./consumer"

document.addEventListener("turbo:load", () => {
  const elements = document.querySelectorAll("[data-scooter-id]")
  
  elements.forEach(element => {
    const scooterId = element.dataset.scooterId
    
    consumer.subscriptions.create({ channel: "ScooterChannel", id: scooterId }, {
      received(data) {
        if (data.type === 'telemetry_update' || data.type === 'command_completed') {
          const scooterData = data.scooter
          this.updateScooterStatus(element, scooterData)
        }
      },

      updateScooterStatus(element, scooter) {
        // Update lock/unlock button
        const lockButton = element.querySelector("[data-action='lock']")
        const unlockButton = element.querySelector("[data-action='unlock']")
        if (lockButton && unlockButton) {
          if (scooter.scooter_state === 'locked') {
            lockButton.style.display = 'none'
            unlockButton.style.display = 'block'
          } else {
            lockButton.style.display = 'block'
            unlockButton.style.display = 'none'
          }
        }

        // Update state display
        const stateElement = element.querySelector("[data-scooter-state]")
        if (stateElement) {
          stateElement.textContent = scooter.scooter_state
        }

        // Update blinker buttons
        const blinkerButtons = element.querySelectorAll("[data-blinker-action]")
        blinkerButtons.forEach(button => {
          const action = button.dataset.blinkerAction
          button.classList.toggle('active', action === scooter.blinkers)
        })

        // Update battery levels
        const updateBattery = (name, value) => {
          const element = document.querySelector(`[data-battery="${name}"]`)
          if (element) {
            element.textContent = `${value}%`
          }
        }

        updateBattery('main', scooter.battery0_level)
        updateBattery('second', scooter.battery1_level)
        updateBattery('aux', scooter.aux_battery_level)
        updateBattery('cbb', scooter.cbb_battery_level)

        // Update online status
        const onlineElement = element.querySelector("[data-online-status]")
        if (onlineElement) {
          onlineElement.textContent = scooter.online ? 'Online' : 'Offline'
          onlineElement.classList.toggle('online', scooter.online)
          onlineElement.classList.toggle('offline', !scooter.online)
        }
      }
    })
  })
})