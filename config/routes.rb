# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  get "/rails/active_storage/transcoded/:signed_blob_id/:encoding_key/*filename" =>
          "transcoding#show",
      as:                                                                        :rails_blob_transcoding,
      internal:                                                                  true

  direct :rails_transcoding do |transcoder, options|
    signed_blob_id = transcoder.blob.signed_id
    encoding_key   = transcoder.encoding.key
    filename       = transcoder.filename

    route_for(:rails_blob_transcoding, signed_blob_id, encoding_key, filename, options)
  end

  resolve("Transcode") { |transcode, options| route_for(:rails_transcoding, transcode, options) }

  resources :episodes, only: %i[index show create update destroy]
  resource :session, only: %i[create destroy]

  if Rails.env.cypress?
    require "reset_cypress"
    get "/cypress/reset" => ResetCypress.new
  end

  if Rails.env.development?
    require "sidekiq/web"
    mount Sidekiq::Web => "sidekiq"
  end

  root to: redirect(Rails.application.config.x.urls[:frontend_url])
end
