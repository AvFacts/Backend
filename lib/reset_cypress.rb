# frozen_string_literal: true

# Rack application that an endpoint allowing the Cypress front-end to reset the
# database before each E2E test run. Only mounted in the `cypress` environment.

class ResetCypress

  # @private
  def call(_env)
    reset
    create_fixtures
    return response
  end

  private

  def reset = models.each { truncate _1 }

  def response = [200, {"Content-Type" => "text/plain"}, ["Cypress reset finished"]]

  def models = [ActiveStorage::Blob, ActiveStorage::Attachment, User, Episode]

  def truncate(model)
    model.connection.execute "TRUNCATE #{model.quoted_table_name} CASCADE"
  end

  def create_fixtures
    User.create! username: "cypress", password: "password123"

    Episode.create! title:       "Unpublished episode",
                    description: "Episode 2 description",
                    script:      "Episode 2 script"

    episode = Episode.new(title:        "Published episode",
                          description:  "Episode 1 description",
                          published_at: Time.current)
    episode.audio.attach io:       Rails.root.join("spec", "fixtures", "files", "audio.aif").open,
                         filename: "audio.aif"
    episode.image.attach io:       Rails.root.join("spec", "fixtures", "files", "image.jpg").open,
                         filename: "image.jpg"
    episode.save!
    episode.preprocess!
  end
end
