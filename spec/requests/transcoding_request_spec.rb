# frozen_string_literal: true

require "rails_helper"
require "transcode"

RSpec.describe "transcoding" do
  include Rails.application.routes.url_helpers
  describe "#show" do
    before :each do
      @episode = create(:episode)
    end

    it "redirects to the service URL for a transcoded file" do
      signed_path = polymorphic_url(@episode.audio.transcode("mp3", %w[-ac 1]), host: "example.com")
      parts       = signed_path.split("/")
      get "/rails/active_storage/transcoded/#{parts[6]}/#{parts[7]}/#{parts[8]}"
      expect(response.headers["Location"]).
          to match(%r{^http://www\.example\.com/rails/active_storage/disk/.+/audio\.mp3$})
    end

    it "renders a 404 for an unknown blob" do
      blob = ActiveStorage.verifier.generate("hello", purpose: :blob_id)
      get "/rails/active_storage/transcoded/#{blob}/world/foo.txt"
      expect(response).to have_http_status(:not_found)
    end
  end
end
