# frozen_string_literal: true

require "rails_helper"

RSpec.describe Episode do
  context "number" do
    it "starts at 1" do
      described_class.destroy_all
      expect(create(:episode).number).to eq(1)
    end

    it "increments" do
      described_class.destroy_all
      create :episode, number: 3
      expect(create(:episode).number).to eq(4)
    end
  end

  describe "#published?" do
    it "returns true for a published episode" do
      expect(create(:episode, published_at: 1.day.ago)).to be_published
    end

    it "returns false for an unpublished episode" do
      expect(create(:episode, published_at: nil)).not_to be_published
    end

    it "returns false for a future-dated episode" do
      expect(create(:episode, published_at: 1.day.from_now)).not_to be_published
    end
  end

  describe "#mp3" do
    it "returns the MP3 Transcode" do
      episode = create(:episode)
      expect(episode.mp3).to be_a(Transcode)
      expect(episode.mp3.blob).to eq(episode.audio.blob)
      expect(episode.mp3.encoding.format).to eq("mp3")
    end

    it "returns nil if the audio hasn't been added yet" do
      episode = create(:episode, audio: nil)
      expect(episode.mp3).to be_nil
    end
  end

  describe "#aac" do
    it "returns the AAC Transcode" do
      episode = create(:episode)
      expect(episode.aac).to be_a(Transcode)
      expect(episode.aac.blob).to eq(episode.audio.blob)
      expect(episode.aac.encoding.format).to eq("aac")
    end

    it "returns nil if the audio hasn't been added yet" do
      episode = create(:episode, audio: nil)
      expect(episode.aac).to be_nil
    end
  end

  describe "#thumbnail_image" do
    it "returns the thumbnail image" do
      episode = create(:episode)
      episode.image.analyze
      expect(episode.thumbnail_image).to be_a(ActiveStorage::VariantWithRecord)
      expect(episode.thumbnail_image.blob).to eq(episode.image.blob)
      expect(episode.thumbnail_image.variation.transformations).
          to eq(format: "jpg", resize_to_fill: [200, 200])
    end

    it "returns nil if the image is nil" do
      episode = create(:episode, image: nil)
      expect(episode.thumbnail_image).to be_nil
    end
  end

  describe "#preprocess!" do
    it "preprocesses the episode and image data" do
      episode = create(:episode)
      episode.preprocess!
      episode.reload
      expect(episode.mp3).to be_processed
      expect(episode.aac).to be_processed
      expect(episode.thumbnail_image.send(:processed?)).to be(true)
      expect(episode.mp3_size).to be_within(128).of(33_271)
      expect(episode.aac_size).to be_within(128).of(22_128) # different ffmpeg versions on travis/local
    end

    it "sets processed and set published_at if the episode is ready" do
      episode = create(:episode, published_at: nil)
      episode.preprocess!
      expect(episode).to be_processed
      expect(episode.published_at).to eq(Time.current)
    end

    it "does not change processed or published_at if the episode is not yet ready" do
      episode = create(:episode, published_at: 1.day.ago, audio: nil)
      episode.preprocess!
      expect(episode).not_to be_processed
      expect(episode.published_at).to eq(1.day.ago)
    end

    it "does not change published_at if the episode is to be published in the future" do
      episode = create(:episode, published_at: 1.day.from_now)
      episode.preprocess!
      expect(episode).to be_processed
      expect(episode.published_at).to eq(1.day.from_now)
    end

    it "does not change published_at if the episode has already been published" do
      episode = create(:episode, published_at: 1.day.ago)
      episode.preprocess!
      expect(episode).to be_processed
      expect(episode.published_at).to eq(1.day.ago)
    end
  end

  describe "[hooks]" do
    it "preprocesses the episode and image data" do
      pending "Does not work inside of transactionalized tests"
      episode = create(:episode)
      expect(episode.mp3).to be_processed
      expect(episode.aac).to be_processed
      expect(episode.thumbnail_image.send(:processed?)).to be(true)
    end
  end
end
