module Scooter::Broadcastable
  extend ActiveSupport::Concern
  include ActionView::RecordIdentifier

  included do
    after_update_commit :broadcast_updates
  end

  private

  def broadcast_updates
    broadcast_state_update
    broadcast_batteries_update
    broadcast_controls_update if saved_change_to_state? || saved_change_to_blinkers?

    broadcast_replace_to self,
      target: "scooter_#{id}_visual",
      partial: "scooters/visual_status",
      locals: { scooter: self } if saved_change_to_state? || saved_change_to_blinkers?

    if saved_change_to_blinkers? || saved_change_to_state?
      broadcast_update_later_to(
        self,
        target: "scooter_#{id}_blinkers",
        partial: "scooters/blinkers",
        locals: { scooter: self }
      )
    end

    if saved_change_to_speed?
      broadcast_update_later_to(
        self,
        target: "scooter_#{id}_speed",
        partial: "scooters/speed",
        locals: { scooter: self }
      )
    end
  end

  def broadcast_state_update
    # Broadcast individual state changes
    if saved_change_to_state?
      broadcast_update_to "state", state
    end
    if saved_change_to_kickstand?
      broadcast_update_to "kickstand", kickstand
    end
    if saved_change_to_seatbox?
      broadcast_update_to "seatbox", seatbox
    end
    if saved_change_to_blinkers?
      broadcast_update_to "blinkers", blinkers
    end
    if saved_change_to_last_seen_at?
      broadcast_update_to "last_seen", last_seen_text
      broadcast_update_to "online_status", is_online? ? "Online" : "Offline"
    end
  end

  def broadcast_batteries_update
    if saved_change_to_battery0_level?
      broadcast_update_to "battery0", number_to_percentage(battery0_level, precision: 1)
    end
    if saved_change_to_battery1_level?
      broadcast_update_to "battery1", number_to_percentage(battery1_level, precision: 1)
    end
    if saved_change_to_aux_battery_level?
      broadcast_update_to "aux_battery", number_to_percentage(aux_battery_level, precision: 1)
    end
    if saved_change_to_cbb_battery_level?
      broadcast_update_to "cbb_battery", number_to_percentage(cbb_battery_level, precision: 1)
    end
  end

  def broadcast_controls_update
    broadcast_update_to "controls",
      ApplicationController.render(partial: "scooters/controls", locals: { scooter: self })
  end

  def broadcast_update_to(target, content)
    broadcast_update_later_to(
      target: "#{self.class.name.underscore}_#{id}", # _#{target}",
      html: content
    )
  end

  def last_seen_text
    last_seen_at ? "#{ApplicationController.helpers.time_ago_in_words(last_seen_at)} ago" : "Never"
  end

  def number_to_percentage(number, options = {})
    ApplicationController.helpers.number_to_percentage(number, options)
  end
end
