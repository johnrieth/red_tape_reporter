class Rack::Attack
  # Custom response for blocked requests
  Rack::Attack.blocklisted_responder = lambda do |env|
    [429, { 'Content-Type' => 'text/plain' }, ['Too Many Requests. Please try again later.']]
  end

  # Instrumentation for monitoring
  self.notifier = ActiveSupport::Notifications

  # Subscribe to rack attack events for logging
  ActiveSupport::Notifications.subscribe(/rack_attack/) do |name, started, finished, unique_id, payload|
    request = payload[:request]
    event_type = request.env["rack.attack.match_type"]
    Rails.logger.info "[Rack::Attack] #{event_type}: #{request.ip} - #{request.path}"
  end

  # Allow local IPs (safelist)
  safelist("allow localhost") do |req|
    ['127.0.0.1', '::1'].include?(req.ip) || req.ip.start_with?('192.168.')
  end

  # Throttles
  throttle("reports/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/reports" && req.post?
  end

  throttle("reports/email", limit: 3, period: 1.day) do |req|
    if req.path == "/reports" && req.post?
      req.params.dig("report", "email")&.strip&.downcase.presence
    end
  end

  # Optional: Throttle password resets
  throttle("password resets/ip", limit: 2, period: 1.hour) do |req|
    req.ip if req.path == "/passwords" && req.post?
  end

  throttle("password resets/email", limit: 1, period: 1.day) do |req|
    if req.path == "/passwords" && req.post?
      req.params.dig("password", "email")&.downcase.presence
    end
  end
end
