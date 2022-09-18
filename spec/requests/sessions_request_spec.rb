require 'rails_helper'
require 'securerandom'

RSpec.describe '/sessions', type: :request do
  describe '#create' do
    before :each do
      @password = SecureRandom.base58
      @user     = create(:user, password: @password)
    end

    it "should log a user in and return the token" do
      post '/session.json', params: {username: @user.username, password: @password}
      expect(response).to have_http_status(:ok)
      expect(response.headers['Authorization']).to match(/^Bearer /)
    end

    it "should 401 if the username is incorrect" do
      post '/session.json', params: {username: 'not-found', password: @password}
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['Authorization']).to be_nil
    end

    it "should 401 if the password is incorrect" do
      post '/session.json', params: {username: @user.username, password: 'incorrect'}
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['Authorization']).to be_nil
    end
  end

  describe '#destroy' do
    it "should invalidate the JWT" do
      auth = login_as_admin

      delete '/session.json', headers: {'Authorization' => auth}
      expect(response).to have_http_status(:ok)

      post '/episodes.json', headers: {'Authorization' => auth}
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
