# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.2.2"

# FRAMEWORK
gem "bootsnap"
gem "configoro"
gem "rack-cors"
gem "rails", "~>7"
gem "sidekiq"

# MODELS
gem "active_storage_validations"
gem "bcrypt"
gem "image_processing"
gem "mini_magick"
gem "pg"
gem "streamio-ffmpeg"

# CONTROLLERS
gem "responders"

# VIEWS
# JSON
gem "jbuilder"
# XML
gem "builder"

# OTHER
gem "json"
gem "nokogiri"
gem "warden"
gem "warden-jwt_auth"
gem "whenever"

# ERRORS
gem "bugsnag"

group :development do
  gem "listen"
  gem "puma"

  # DEVELOPMENT
  gem "binding_of_caller"

  # DEPLOYMENT
  gem "bcrypt_pbkdf", require: false
  gem "bugsnag-capistrano", require: false
  gem "capistrano", require: false
  gem "capistrano-bundler", require: false
  gem "capistrano-git-with-submodules", require: false
  gem "capistrano-nvm", require: false
  gem "capistrano-rails", require: false
  gem "capistrano-rvm", require: false
  gem "capistrano-sidekiq", require: false
  gem "ed25519", require: false
end

group :test do
  # SPECS
  gem "rails-controller-testing"
  gem "rspec-rails"

  # ISOLATION
  gem "database_cleaner"
  gem "fakefs", require: "fakefs/safe"
  gem "timecop"
  gem "webmock", require: "webmock/rspec"

  # FACTORIES
  gem "factory_bot_rails"
  gem "ffaker"
end

group :production do
  # CACHE
  gem "redis"

  # ACTIVE STORAGE
  gem "aws-sdk-s3", require: false
end

group :doc do
  gem "redcarpet"
  gem "yard", require: nil
end
