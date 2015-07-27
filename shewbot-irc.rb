require 'cinch'
require 'dotenv'
require 'rest-client'
require 'json'
require 'securerandom'
$stdout.sync = true

if ARGV.first
  Dotenv.load(ARGV.first)
else
  Dotenv.load
end

class OverloadError < RuntimeError
end


ENV['BOTCHANNEL'] = '#' + ENV['BOTCHANNEL']

$user_hash = {}

bot = Cinch::Bot.new do

  configure do |c|
    c.server   = ENV['IRC_SERVER']
    c.channels = [ENV['BOTCHANNEL']]
    c.nick = ENV['BOTNAME']
  end

  on :private, /^![slq] / do |m|
    m.user.send "Suggestions are no longer accepted via private message due to possible abuse. Please submit suggestions in channel."
  end

  on :message, /^!quiet/ do |m|
    begin
      RestClient.post ENV['QUIET_URL'], 
        {user: m.user.nick}.to_json, 
        :content_type => :json, :'Authorization' => 'Token token="' + ENV['API_KEY'] + '"'
        m.user.send "I'll be quiet now. Sorry to have bothered you with my helpful messages."
    rescue => e 
      if e.http_code == 422
        result_message = ""
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

  on :channel, /^![Ss] (.*$)/ do |m, title|
    puts "Got title suggestion #{title}"

    begin

      if $user_hash.has_key?(m.user.nick.to_sym)
        puts "#{m.user.nick} - #{$user_hash[m.user.nick.to_sym]} - #{(Time.new - $user_hash[m.user.nick.to_sym]).to_int}"
        if (Time.new - $user_hash[m.user.nick.to_sym]).to_int < 1
          raise OverloadError, "Submitting too fast"
        end
      end

      $user_hash[m.user.nick.to_sym] = Time.new

      RestClient.post ENV['TITLE_SUBMISSION_URL'], 
        {title: title, user: m.user.nick, host: m.user.host, username: m.user.user}.to_json, 
        :content_type => :json, :'Authorization' => 'Token token="' + ENV['API_KEY'] + '"'
        m.user.send "'#{title}' accepted"
    rescue ArgumentError
      m.user.send "!s is not enabled"
    rescue OverloadError
      m.user.send "You are submitting too fast"
    rescue => e
      http_code = e.http_code rescue nil
      if http_code == 422
        result_message = "Problems with '#{title}': "
        JSON.parse(e.response).each do | key, value | 
          if key == 'show_id'
            result_message << 'show is not live'
          elsif key == 'title_lc'
            result_message << 'title already submitted'
          else
            value.each do | message |
              result_message << key + ' ' + message + '. '
            end
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

  on :channel, /^![Ll] (.*$)/ do |m, link|
    puts "Got link suggestion #{link}"

    begin
      RestClient.post ENV['LINK_SUBMISSION_URL'], 
        {url: link, user: m.user.nick, host: m.user.host, username: m.user.user}.to_json, 
        :content_type => :json, :'Authorization' => 'Token token="' + ENV['API_KEY'] + '"'
        m.user.send "'#{link}' accepted"
    rescue ArgumentError
      m.user.send "!l is not enabled"
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

  on :channel, /^![Qq] (.*$)/ do |m, link|
    puts "Got question #{link}"

    begin
      RestClient.post ENV['QUESTION_SUBMISSION_URL'], 
        {question: link, user: m.user.nick, host: m.user.host, username: m.user.user}.to_json, 
        :content_type => :json, :'Authorization' => 'Token token="' + ENV['API_KEY'] + '"'
        m.user.send "'#{link}' accepted"
    rescue ArgumentError
      m.user.send "!q is not enabled"
    rescue => e 
      puts e.inspect

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
    help_message = '!help - this'
    help_message << '; !quiet - bot will stop sending you successful title confirmation' if !ENV['QUIET_URL'].nil?
    help_message << '; !s - suggest a title' if !ENV['TITLE_SUBMISSION_URL'].nil?
    help_message << '; !l - suggest a link' if !ENV['LINK_SUBMISSION_URL'].nil?
    help_message << '; !q - suggest a question' if !ENV['QUESTION_SUBMISSION_URL'].nil?

    m.user.send help_message
  end


end

bot.start

