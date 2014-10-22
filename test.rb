require 'cinch'
require 'dotenv'
require 'rest-client'
require 'json'
require 'securerandom'

title = 'this title is way to long it will never work oh the hue manity'
title = 'The Elite'

begin
  RestClient.post 'http://shewbot-rails.herokuapp.com/titles/create', 
    {title: title, user: 'testuser'}.to_json, 
    :content_type => :json, :'Authorization' => 'Token token="5f372f8960e2b0881713e0958cf7bb4a"'
  puts "'#{title}' accepted"
rescue => e 
  if e.http_code == 422
    puts e.response
    result_message = "Problems with '#{title}': "
    JSON.parse(e.response).each do | key, value | 
      value.each do | message |
        result_message << message + '. '
      end
    end
    puts result_message
  else
    code = SecureRandom.hex
    puts "An unhandled error occured - #{code}: " + e.inspect
  end
end


