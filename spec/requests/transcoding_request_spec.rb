require 'rails_helper'
require 'transcode'

RSpec.describe 'transcoding', type: :request do
  include Rails.application.routes.url_helpers
  describe '#show' do
    before :each do
      @episode = FactoryBot.create(:episode)
    end

    it "should redirect to the service URL for a transcoded file" do
      signed_path = polymorphic_url(@episode.audio.transcode('mp3', %w[-ac 1]), host: 'example.com')
      parts       = signed_path.split('/')
      get "/rails/active_storage/transcoded/#{parts[6]}/#{parts[7]}/#{parts[8]}"
      expect(response.headers['Location']).
        to match(/^http:\/\/www\.example\.com\/rails\/active_storage\/disk\/.+\/audio\.mp3$/)
    end

    it "should render a 404 for an unknown blob" do
      blob = ActiveStorage.verifier.generate('hello', purpose: :blob_id)
      get "/rails/active_storage/transcoded/#{blob}/world/foo.txt"
      expect(response.status).to eql(404)
    end
  end
end
