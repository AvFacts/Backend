# frozen_string_literal: true

# Helper methods for the RSS and JSON views of {EpisodesController}.

module EpisodesHelper

  # Returns a URL for the JavaScript front-end.
  #
  # @param [String] path The URI path.
  # @return [String] The full front-end URL.

  def frontend_url(path="/")
    URI.join(Rails.application.config.x.urls[:frontend_url], path)
  end

  # @return [Hash<String, Object>] Returns a hash of configuration information
  #   about the AvFacts podcast, used for populating the RSS feed with channel
  #   information. This data is defined in `channel.json`.

  def channel
    @channel ||= JSON.parse(Rails.root.join("channel", "channel.json").read).with_indifferent_access
  end

  # @return [Time] The date of the most recently-published episode, which serves
  #   as the RSS feed's publication date. Returns the current time if there are
  #   no episodes yet.

  def publication_date
    @publication_date ||= Episode.published.order(published_at: :desc).first&.published_at ||
        Time.current
  end

  # Returns the full formatted title of the episode used in the episode list
  # (e.g., "#5: Title Name").
  #
  # @param [Episode] episode The episode.
  # @return [String] The full episode title as used in the feed.

  def full_title(episode) = "##{number_with_delimiter episode.number}: #{episode.title}"

  # @param [Episode] episode The episode.
  # @return [String] The description with the credits appended.

  def full_description(episode)
    result = episode.description.dup
    result << "\n\n" << episode.credits if episode.credits?
    return result
  end

  # Given a duration in seconds, returns a colon-separated formatted duration.
  # For example, 350 seconds becomes "0:05:50".
  #
  # @param [Integer] seconds A duration in seconds.
  # @return [String] The formatted duration as colon-separated components.

  def duration_string(seconds)
    seconds = seconds.round
    hours   = (seconds / 3600)
    minutes = (seconds - (hours * 3600)) / 60
    seconds = seconds - (hours * 3600) - (minutes * 60)
    return [
        hours.to_s,
        minutes.to_s.rjust(2, "0"),
        seconds.to_s.rjust(2, "0")
    ].join(":")
  end

  # Constructs nested `<itunes:category>` tags for the given category and
  # subcategory settings as found in the `channel.json` file. The tags are given
  # to the `xml` object, not returned.
  #
  # @param [Builder] xml An XML object being used to render the current
  #   template.
  # @param [String, Array<String>, Hash<String, String>, Hash<String, Array>] categories
  #   The iTunes category or categories for this podcast. For subcategories, a
  #   hash of category to one or more subcategories is used.

  def category_tags(xml, categories)
    case categories
      when String
        xml.itunes :category, text: categories
      when Array
        categories.each { category_tags xml, _1 }
      when Hash
        categories.each do |parent, subcategories|
          xml.itunes(:category, text: parent) do
            category_tags xml, subcategories
          end
        end
    end
  end
end
