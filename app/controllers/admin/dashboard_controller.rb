# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < Admin::ApplicationController
  def index
    @stats = {
      users_count: User.count,
      scooters_count: Scooter.count,
      trips_count: Trip.count,
      telemetries_count: Telemetry.count,
      events_count: ScooterEvent.count,
      recent_users: User.order(created_at: :desc).limit(5),
      recent_scooters: Scooter.order(created_at: :desc).limit(5),
      recent_events: ScooterEvent.order(created_at: :desc).limit(5)
    }
  end
end
