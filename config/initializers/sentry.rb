# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn) || ENV["SENTRY_DSN"]

  # Only enable in production and staging - NOT in development
  config.enabled_environments = %w[production staging]

  # Only configure if enabled
  if config.enabled_environments.include?(Rails.env)
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
    config.send_default_pii = true
    config.enable_logs = true
    config.enabled_patches = [ :logger ]

    # Lower sample rates for production (adjust based on traffic)
    config.traces_sample_rate = 0.1  # 10% of requests
    config.profiles_sample_rate = 0.1  # 10% of traces
  end
end
