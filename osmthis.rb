require 'rubygems'
require 'bundler'

Bundler.require :default

osmthis = '@osmthis'

# Rosemary::Api.base_uri 'http://api06.dev.openstreetmap.org/' # Use test API
osm_client = Rosemary::BasicAuthClient.new(ENV['OSM_USER'], ENV['OSM_PASSWORD'])
osm_api = Rosemary::Api.new(osm_client)

TweetStream.configure do |config|
  config.consumer_key       = ENV['TWITTER_API_KEY']
  config.consumer_secret    = ENV['TWITTER_API_SECRET']
  config.oauth_token        = ENV['TWITTER_OAUTH_TOKEN']
  config.oauth_token_secret = ENV['TWITTER_OAUTH_SECRET']
  config.auth_method        = :oauth
end

TweetStream::Client.new.track(osmthis) do |status|
  if !status.retweet?
    if status.geo?
      puts "Received a tweet: #{status.url}"
      text = "#{status.text}\n\n" +
             "Posted by @#{status.user.user_name} using #{osmthis}\n" +
             "Original tweet: #{status.url}"
      note = osm_api.create_note(lat: status.geo.coordinates[0], lon: status.geo.coordinates[1], text: text.gsub(/^#{osmthis}\s+/, ''))
      puts "Added a note: #{note.inspect}"
      puts "http://www.openstreetmap.org/note/#{note.id}"
    else
      puts "Received a non-geotagged tweet: #{status.url}"
    end
  end
end