require 'cinch'
require 'dotenv'
require 'rest-client'
require 'json'
require 'securerandom'

if ARGV.first
  Dotenv.load(ARGV.first)
else
  Dotenv.load
end


ENV['BOTCHANNEL'] = '#' + ENV['BOTCHANNEL']

bot = Cinch::Bot.new do

  configure do |c|
    c.server   = ENV['IRC_SERVER']
    c.channels = [ENV['BOTCHANNEL']]
    c.nick = ENV['BOTNAME']
  end

  on :message, /^!s (.*$)/ do |m, title|
    puts "Got title suggestion #{title}"

    begin
      RestClient.post ENV['TITLE_SUBMISSION_URL'], 
        {title: title, user: m.user.nick}.to_json, 
        :content_type => :json, :'Authorization' => 'Token token="' + ENV['API_KEY'] + '"'
        m.user.send "'#{title}' accepted"
    rescue => e 
      if e.http_code == 422
        result_message = "Problems with '#{title}': "
        JSON.parse(e.response).each do | key, value | 
          value.each do | message |
            result_message << key + ' ' + message + '. '
          end
        end
        m.user.send result_message
      else
        code = SecureRandom.hex
        m.user.send "Something went wrong. Code: #{code}"
        puts "An unhandled error occured - #{code}: " + e.inspect
      end
    end

  end

  on :message, /^!l (.*$)/ do |m, link|
    puts "Got link suggestion #{link}"

    begin
      RestClient.post ENV['LINK_SUBMISSION_URL'], 
        {url: link, user: m.user.nick}.to_json, 
        :content_type => :json, :'Authorization' => 'Token token="' + ENV['API_KEY'] + '"'
        m.user.send "'#{link}' accepted"
    rescue => e 
      if e.http_code == 422
        result_message = "Problems with '#{link}': "
        JSON.parse(e.response).each do | key, value | 
          value.each do | message |
            result_message << key + ' ' + message + '. '
          end
        end
        m.user.send result_message
      else
        code = SecureRandom.hex
        puts "An unhandled error occured - #{code}: " + e.inspect
        m.user.send "Something went wrong. Code: #{code}"
      end
    end
  end


  on :message, /^!help/ do |m|
    m.user.send "!s - suggest a title; !l - submit a link; !help - this"
  end


end

bot.start

