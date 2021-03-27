# Be sure to restart your server when you modify this file.

ActiveSupport::Reloader.to_prepare do
  ApplicationController.renderer.defaults.merge!(
    http_host: Rails.application.config.x.urls[:http_host],
    https:     Rails.application.config.x.urls[:https]
  )
end
