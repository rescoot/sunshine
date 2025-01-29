class UnuController < ApplicationController
  skip_before_action :verify_authenticity_token
  around_action :silence_rails_logging
  before_action :log_request

  def handle
    head :not_implemented
  end

  private

  def silence_rails_logging
    old_logger = Rails.logger
    Rails.logger = Logger.new(File::NULL)
    yield
  ensure
    Rails.logger = old_logger
  end

  def log_request
    UnuRequest.create!(
      method: request.method,
      path: request.fullpath,
      remote_ip: request.remote_ip,
      headers: filtered_headers,
      body: request_body
    )
  end

  def filtered_headers
    request.headers.to_h.reject do |key, _|
      key.start_with?("rack.", "action_", "puma.")
    end
  end

  def request_body
    return "" unless request.body.size > 0

    begin
      JSON.parse(request.raw_post).to_json
    rescue JSON::ParserError
      request.raw_post
    end
  end
end
