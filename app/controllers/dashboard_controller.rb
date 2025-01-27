class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @scooters = current_user.scooters.includes(:trips)
    @recent_trips = current_user.trips.completed.order(ended_at: :desc).limit(5)

    # Load lifetime statistics
    completed_trips = current_user.trips.where.not(ended_at: nil)
    @lifetime_stats = {
      total_trips: completed_trips.count,
      total_distance: completed_trips.sum(:distance),
      total_time: completed_trips.sum("CAST((ended_at - started_at) AS INTEGER)"),
      avg_trip_distance: completed_trips.average(:distance),
      avg_speed: completed_trips.average(:avg_speed),
      longest_trip: completed_trips.order(distance: :desc).first,
      fastest_trip: completed_trips.order(avg_speed: :desc).first,
      scooter_count: @scooters.count,
      trips_this_month: completed_trips.where("started_at >= ?", Time.current.beginning_of_month).count,
      distance_this_month: completed_trips.where("started_at >= ?", Time.current.beginning_of_month).sum(:distance)
    }
  end
end
