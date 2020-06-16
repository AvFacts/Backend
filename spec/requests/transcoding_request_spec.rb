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
      expect(response.headers['Location']).to match(/^http:\/\/www\.example\.com\/rails\/active_storage\/disk\/.+\/audio\.mp3\?content_type=audio%2Fmpeg&disposition=inline%3B\+filename%3D%22audio\.mp3%22%3B\+filename%2A%3DUTF-8%27%27audio\.mp3$/)
    end

    it "should render a 404 for an unknown blob" do
      blob = ActiveStorage.verifier.generate('hello', purpose: :blob_id)
      expect { get "/rails/active_storage/transcoded/#{blob}/world/foo.txt" }.
          to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
