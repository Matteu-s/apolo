require 'net/http'
require 'uri'
require 'json'

class HomeController < ApplicationController
  HACKER_NEWS_API = 'https://hacker-news.firebaseio.com/v0'.freeze
  STORIES_LIMIT = 15
  CACHE_EXPIRY = 5.minutes

  def index
    @stories = Rails.cache.fetch('top_stories', expires_in: CACHE_EXPIRY) do
      story_ids = fetch_story_ids
      stories = fetch_story_details(story_ids)
      stories.sort_by { |story| -story['time'].to_i }
    end
  end

  def comments
    @story = fetch_story_details(params[:id])
    @comments = Rails.cache.fetch("comments_#{params[:id]}", expires_in: CACHE_EXPIRY) do
      fetch_comments(@story['kids']) if @story['kids']
    end  
  end

  private

  def fetch_story_ids
    url = "#{HACKER_NEWS_API}/topstories.json?orderBy=\"$key\"&limitToFirst=#{STORIES_LIMIT}"
    make_request(url) || []
  end

  def fetch_story_details(story_ids)
    return [] if story_ids.nil?
    
    if story_ids.is_a?(String) || story_ids.is_a?(Integer)
      url = "#{HACKER_NEWS_API}/item/#{story_ids}.json"
      make_request(url) || {}
    else
      story_ids.map do |id|
        url = "#{HACKER_NEWS_API}/item/#{id}.json"
        make_request(url)
      end.compact
    end
  end

  def fetch_comments(kids_ids, depth = 0)
    return [] if kids_ids.nil? || depth > 2
    
    kids_ids.map do |id|
      url = "#{HACKER_NEWS_API}/item/#{id}.json"
      comment = make_request(url)
      next if comment.nil? || comment['deleted']
      next if comment['text'].to_s.split.size < 20
      
      if comment['kids']
        comment['replies'] = fetch_comments(comment['kids'], depth + 1)
      end
      comment
    end.compact
  end

  def make_request(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    
    return nil unless response.is_a?(Net::HTTPSuccess)
    
    JSON.parse(response.body)
  rescue JSON::ParserError => e
    Rails.logger.error("Erro ao fazer parse da resposta de #{url}: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("Erro na requisição para #{url}: #{e.message}")
    nil
  end
end