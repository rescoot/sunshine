// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"
// import "@rails/actioncable"

import * as ActionCable from '@rails/actioncable'

ActionCable.logger.enabled = true

addEventListener("turbo:before-stream-render", (event) => {
  console.log("Turbo Stream received:", event.target);
});
