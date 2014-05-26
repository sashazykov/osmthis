require 'rubygems'
require 'bundler'

Bundler.require :default

osmthis = '@osmthis'

# Rosemary::Api.base_uri 'http://api06.dev.openstreetmap.org/' # Use test API
osm_client = Rosemary::BasicAuthClient.new(ENV['OSM_USER'], ENV['OSM_PASSWORD'])
osm_api = Rosemary::Api.new(osm_client)

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['TWITTER_API_KEY']
  config.consumer_secret     = ENV['TWITTER_API_SECRET']
  config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
  config.access_token_secret = ENV['TWITTER_OAUTH_SECRET']
end

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
      if note.id && note.id != ''
        client.update "@#{status.user.user_name} Thank you! You can find your note here: http://www.openstreetmap.org/note/#{note.id}", in_reply_to_status_id: status.id
      else
        puts "Error: #{note.inspect}"
      end
    else
      puts "Received a non-geotagged tweet: #{status.url}"
      client.update "@#{status.user.user_name} The tweet should be geotagged to be posted to OSM", in_reply_to_status_id: status.id
    end
  end
end