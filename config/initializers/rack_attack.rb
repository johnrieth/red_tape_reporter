class Rack::Attack
  # Custom response for blocked requests
  Rack::Attack.blocklisted_responder = lambda do |env|
    [429, { 'Content-Type' => 'text/plain' }, ['Too Many Requests. Please try again later.']]
  end

  # Logging for monitoring
  self.notifier = ->(type, req, options) {
    Rails.logger.info "[Rack::Attack] #{type}: #{req.ip} - #{req.path}"
  }

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
