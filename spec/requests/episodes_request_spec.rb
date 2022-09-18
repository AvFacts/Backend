require 'rails_helper'

RSpec.describe '/episodes', type: :request do
  describe '#index' do
    context '[JSON]' do
      context '[filtering]' do
        before :each do
          @episodes = Array.new(5) { |i| create :episode, number: i + 100, processed: true }
          @episodes.shuffle.each_with_index { |e, i| e.update number: i + 1 }

          # red herrings
          @unpublished = create(:episode, processed: true, published_at: 1.day.from_now)
          @blocked     = create(:episode, processed: true, blocked: true)
          @draft       = create(:episode, audio: nil)
        end

        it "should list episodes in order filtering unpublished episodes" do
          get '/episodes.json'
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json.map { |j| j['number'] }).
              to eq(@episodes.map(&:number).sort.reverse)
        end

        it "should not withhold blocked episodes for JSON requests from admins" do
          auth = login_as_admin
          get '/episodes.json', headers: {'Authorization' => auth}
          json = JSON.parse(response.body)
          expect(json.map { |j| j['number'] }).
              to include(@blocked.number)
        end

        it "should not withhold unpublished episodes for JSON requests from admins" do
          auth = login_as_admin
          get '/episodes.json', headers: {'Authorization' => auth}
          json = JSON.parse(response.body)
          expect(json.map { |j| j['number'] }).
              to include(@unpublished.number, @draft.number)
        end
      end

      context '[pagination]' do
        before :each do
          @episodes = Array.new(15) { |i| create :episode, number: i + 100, processed: true }
          @episodes.shuffle.each_with_index { |e, i| e.update number: i + 1 }
        end

        it "should paginate" do
          get '/episodes.json'
          expect(response.headers['X-Next-Page']).to eq('/episodes.json?before=6')
          json = JSON.parse(response.body)
          expect(json.map { |j| j['number'] }).
              to eq(@episodes.map(&:number).sort.reverse[0, 10])

          get '/episodes.json?before=6'
          expect(response.headers['X-Next-Page']).to be_nil
          json = JSON.parse(response.body)
          expect(json.map { |j| j['number'] }).
              to eq(@episodes.map(&:number).sort.reverse[10, 10])
        end

        it "should accept a 'before' parameter" do
          get '/episodes.json?before=3'
          json = JSON.parse(response.body)
          expect(json.map { |j| j['number'] }).
              to eq(@episodes.map(&:number).sort.reverse[-2..])
        end
      end

      context '[searching]' do
        before :each do
          @included = create_list(:episode, 3, script: "SearchTerm #{FFaker::HipsterIpsum.sentence}", processed: true)
          @no_match = create(:episode, script: FFaker::HipsterIpsum.sentence, processed: true)
        end

        it "should accept a search query" do
          get '/episodes.json?filter=SearchTerm'
          json = JSON.parse(response.body).map { |j| j['number'] }
          expect(json).to match_array(@included.map(&:number))
        end
      end
    end

    context '[RSS]' do
      before :each do
        @episodes = Array.new(3) { |i| create :episode, number: i + 100 }
        @episodes.shuffle.each_with_index { |e, i| e.update number: i + 1 }

        # red herrings
        @unpublished = create(:episode, processed: true, published_at: 1.day.from_now)
        @blocked     = create(:episode, processed: true, blocked: true)
        @draft       = create(:episode, audio: nil)

        [*@episodes, @unpublished, @blocked].each(&:preprocess!)

        @included_episodes = [*@episodes, @blocked]

        @included_episodes.max_by(&:number).update credits: "Some\ncredits"
      end

      it "should render the RSS feed" do
        get '/episodes.rss'
        expect(response).to have_http_status(:ok)
        xml = Nokogiri::XML(response.body)

        items = xml.xpath('//rss/channel/item')
        expect(items.map { |i| i.xpath('title').first.content }).
            to eq(@included_episodes.sort_by(&:number).reverse.map { |e| "##{e.number}: #{e.title}" })
        expect(items.first.xpath('description').first.content).to end_with(<<~EOS.chomp)

          Some
          credits
        EOS
      end
    end
  end

  describe '#show' do
    let(:processed_episode) do
      episode = create(:episode, script: "Hello, world!")
      episode.preprocess!
      episode
    end
    let(:unprocessed_episode) { create(:episode) }
    let(:draft_episode) { create :episode, audio: nil, image: nil }

    context '[JSON]' do
      it "should render the show template" do
        get "/episodes/#{processed_episode.to_param}.json"
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['number']).to eq(processed_episode.number)
        expect(json).not_to include('script')
      end

      context '[logged in]' do
        before(:each) { @auth = login_as_admin }

        it "should include the script" do
          get "/episodes/#{processed_episode.to_param}.json", headers: {'Authorization' => @auth}
          json = JSON.parse(response.body)
          expect(json['script']).to eq("Hello, world!")
        end
      end
    end

    %w[mp3 aac].each do |format|
      context "[#{format.upcase}]" do
        before :each do
          stub_request(:get, /^http:\/\/www\.example\.com\/rails\/active_storage\/disk/).
              to_return(status: 200, body: "this is not a very well-formatted audio file")
        end

        it "should stream" do
          get "/episodes/#{processed_episode.to_param}.#{format}"
          expect(response).to have_http_status(:ok)
          expect(response.body).to eq("this is not a very well-formatted audio file")
        end

        it "should 404 if the audio hasn't been added yet" do
          get "/episodes/#{draft_episode.to_param}.#{format}"
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end

        it "should 404 if the audio hasn't been processed yet" do
          get "/episodes/#{unprocessed_episode.to_param}.#{format}"
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end
      end
    end
  end

  describe '#create' do
    before :each do
      @episode_params         = attributes_for(:episode)
      @episode_params[:audio] = fixture_file_upload('audio.aif', 'audio/aiff')
      @episode_params[:image] = fixture_file_upload('image.jpg', 'image/jpeg')
      @auth = login_as_admin
    end

    it "should require admin" do
      post '/episodes.json', params: {episode: @episode_params}
      expect(response).to have_http_status(:unauthorized)
    end

    it "should make an episode" do
      post '/episodes.json', params: {episode: @episode_params}, headers: {'Authorization' => @auth}
      expect(response).to have_http_status(:created)
      expect(Episode.count).to eq(1)
      expect(Episode.first.title).to eq(@episode_params[:title])
    end

    it "should handle validation errors" do
      post '/episodes.json', params: {episode: @episode_params.merge(title: " ")}, headers: {'Authorization' => @auth}
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe '#update' do
    before :each do
      @episode = create(:episode)
      @auth = login_as_admin
    end

    it "should require admin" do
      patch "/episodes/#{@episode.to_param}.json", params: {episode: {title: "New Title"}}
      expect(response).to have_http_status(:unauthorized)
    end

    it "should update an episode" do
      patch "/episodes/#{@episode.to_param}.json", params: {episode: {title: "New Title"}}, headers: {'Authorization' => @auth}
      expect(response).to have_http_status(:ok)
      expect(@episode.reload.title).to eq("New Title")
    end

    it "should handle validation errors" do
      patch "/episodes/#{@episode.to_param}.json", params: {episode: {title: " "}}, headers: {'Authorization' => @auth}
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe '#destroy' do
    before :each do
      @episode = create(:episode)
      @auth = login_as_admin
    end

    it "should require admin" do
      delete "/episodes/#{@episode.to_param}.json"
      expect(response).to have_http_status(:unauthorized)
    end

    it "should delete an episode" do
      delete "/episodes/#{@episode.to_param}.json", headers: {'Authorization' => @auth}
      expect(response).to have_http_status(:no_content)
      expect { @episode.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
