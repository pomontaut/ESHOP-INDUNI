require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # public/ holds live app pages (catalogue.html, bon_de_commande.html), not
  # digest-stamped assets — force revalidation so deploys aren't masked by stale caches.
  config.public_file_server.headers = { "cache-control" => "public, max-age=0, must-revalidate" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Use SECRET_KEY_BASE env var if set; otherwise fall back to a fixed key so
  # sessions survive redeploys even when Railway variables aren't configured.
  # Prefer setting SECRET_KEY_BASE in Railway variables when possible.
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE",
    "1da4ade4ee59cb39402175eaa6d30050190b43cc52b68ecb09f590d1f3eec820734b1115da7b61bfcabdb50ae36e85310e6d968800944650b49c9b8f171dec4d")

  # Allow all hosts (Railway proxy sets Host header dynamically)
  config.hosts = nil

  # Trust SSL termination at Railway's proxy level
  config.assume_ssl = true

  # Cache en mémoire (simple, pas de DB séparée)
  config.cache_store = :memory_store

  # Jobs asynchrones (pas de solid_queue)
  config.active_job.queue_adapter = :async

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: ENV.fetch("RAILWAY_PUBLIC_DOMAIN", "eshop-induni-production.up.railway.app"), protocol: "https" }

  # SMTP via Microsoft 365 — configure SMTP_USERNAME and SMTP_PASSWORD in Railway variables
  if ENV["SMTP_USERNAME"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              ENV["SMTP_ADDRESS"].to_s.strip.presence || "smtp.office365.com",
      port:                 ENV["SMTP_PORT"].to_s.strip.presence&.to_i || 587,
      domain:               ENV["SMTP_DOMAIN"].to_s.strip.presence || "induni.ch",
      user_name:            ENV["SMTP_USERNAME"].to_s.strip,
      password:             ENV["SMTP_PASSWORD"].to_s.strip,
      authentication:       :login,
      enable_starttls_auto: true
    }
    config.action_mailer.raise_delivery_errors = true
  else
    config.action_mailer.delivery_method = :test
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
