# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Avfacts
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.generators do |g|
      g.template_engine     nil
      g.test_framework      :rspec, fixture: true, views: false
      g.integration_tool    :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    config.active_job.queue_name_prefix = "avfacts_#{Rails.env}"

    config.active_record.schema_format = :sql

    require "audio_analyzer"
    config.active_storage.analyzers.append AudioAnalyzer

    config.x.cloudfront = config_for(:cloudfront)
    config.x.urls = config_for(:urls)
  end
end

if Rails.env.production?
  FFMPEG.ffmpeg_binary  = "/var/www/app.avfacts.org/shared/bin/ffmpeg"
  FFMPEG.ffprobe_binary = "/var/www/app.avfacts.org/shared/bin/ffprobe"
end
