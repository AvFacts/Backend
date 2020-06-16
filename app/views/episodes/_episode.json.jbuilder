json.call episode, :number, :title, :subtitle, :summary, :author,
          :description, :published_at, :script?

if defined?(full) && full
  json.call episode, :id, :explicit, :blocked, :credits
  json.script(episode.script) if admin?
end

json.image do
  json.preview_url polymorphic_url(episode.thumbnail_image, only_path: false)

  if defined?(full) && full
    json.width episode.image.metadata['width']
    json.height episode.image.metadata['height']
    json.size episode.image.byte_size
  end
end if episode.thumbnail_image&.processed?

json.audio do
  json.duration episode.audio.metadata[:duration]
  json.size episode.audio.byte_size

  json.mp3 do
    json.url episode.mp3.public_cdn_url
    json.content_type episode.mp3.content_type
    json.byte_size episode.mp3_size
  end

  json.aac do
    json.url episode.aac.public_cdn_url
    json.content_type episode.aac.content_type
    json.byte_size episode.aac_size
  end
end if episode.processed?
