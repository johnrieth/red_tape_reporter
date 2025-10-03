class Rack::Attack
  # Allow 5 submissions per IP per hour
  throttle("reports/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/reports" && req.post?
  end

  # Allow 3 submissions per email per day
  throttle("reports/email", limit: 3, period: 1.day) do |req|
    if req.path == "/reports" && req.post?
      req.params["report"]["email"].presence
    end
  end
end
