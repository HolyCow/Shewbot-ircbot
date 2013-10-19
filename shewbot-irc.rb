require 'cinch'
require 'dotenv'
require 'rest-client'
require 'json'

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
        {title: {title: title}, user: {name: m.user.nick}}.to_json, 
        :content_type => :json, :'Authorization' => 'Token token="' + ENV['API_KEY'] + '"'
        m.user.send "'#{title}' accepted"
    rescue => e 
      if e.http_code == 422
        m.user.send "'#{title}' was already submitted"
      else
        m.user.send "An unhandled error occured - #{e.response}"
      end
    end

  end

  on :message, /^!help/ do |m|
    m.user.send "!s - suggest a title; !help - this"
  end


end

bot.start

