Sentry.init do |config|
  config.dsn = 'https://a755aedf89849b5efdec57f24f189eff@o4510228619853824.ingest.us.sentry.io/4510228620836864'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Add data like request headers and IP for users,
  # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
  config.send_default_pii = true
end
