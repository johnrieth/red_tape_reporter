# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = "https://a755aedf89849b5efdec57f24f189eff@o4510228619853824.ingest.us.sentry.io/4510228620836864"

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
