require 'net/http'
require 'uri'
require 'json'

class HackerNewsService
  HACKER_NEWS_API = 'https://hacker-news.firebaseio.com/v0'.freeze
  STORIES_LIMIT = 15
  NEW_STORIES_LIMIT = 100

  def self.fetch_story_details(story_ids)
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

  def self.fetch_top_stories
    url = "#{HACKER_NEWS_API}/topstories.json?orderBy=\"$key\"&limitToFirst=#{STORIES_LIMIT}"
    make_request(url) || []
  end

  def self.fetch_comments(kids_ids, depth = 0)
    return [] if kids_ids.nil? || depth > 2

    kids_ids.map do |id|
      url = "#{HACKER_NEWS_API}/item/#{id}.json"
      comment = make_request(url)
      next if comment.nil? || comment['deleted'] || comment['text'].to_s.split.size < 20

      comment['replies'] = fetch_comments(comment['kids'], depth + 1) if comment['kids']
      comment
    end.compact
  end

  def self.fetch_new_story_ids
    url = "#{HACKER_NEWS_API}/newstories.json?orderBy=\"$key\"&limitToFirst=#{NEW_STORIES_LIMIT}"
    make_request(url) || []
  end

  def self.search_stories(query)
    return [] if query.blank?

    story_ids = fetch_new_story_ids
    Rails.logger.info "Buscando em #{story_ids.size} histórias"
    stories = story_ids.each_slice(10).flat_map do |batch_ids|
      Rails.logger.info "Processando lote de #{batch_ids.size} histórias"
      fetch_story_details(batch_ids).select do |story|
        story && (story['title'].to_s.downcase.match?(query) || story['text'].to_s.downcase.match?(query))
      end
    end

    stories.sort_by { |story| -story['time'].to_i }.first(10)
  end

  def self.make_request(url)
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
