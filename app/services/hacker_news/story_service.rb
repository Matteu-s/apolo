module HackerNews
  class StoryService < BaseClient
    STORIES_LIMIT = 15
    NEW_STORIES_LIMIT = 500

    def fetch_story_details(story_ids)
      return [] if story_ids.nil?

      if story_ids.is_a?(String) || story_ids.is_a?(Integer)
        make_request("#{api_url}/item/#{story_ids}.json") || {}
      else
        story_ids.map { |id| make_request("#{api_url}/item/#{id}.json") }.compact
      end
    end

    def fetch_top_stories
      make_request("#{api_url}/topstories.json?orderBy=\"$key\"&limitToFirst=#{STORIES_LIMIT}") || []
    end

    def search_stories(query)
      return [] if query.blank?

      story_ids = fetch_new_story_ids
      stories = story_ids.each_slice(10).flat_map do |batch_ids|
        fetch_story_details(batch_ids).select do |story|
          story && matches_query?(story, query)
        end
      end

      stories.sort_by { |story| -story['time'].to_i }.first(10)
    end

    private

    def api_url
      'https://hacker-news.firebaseio.com/v0'
    end

    def fetch_new_story_ids
      make_request("#{api_url}/newstories.json?orderBy=\"$key\"&limitToFirst=#{NEW_STORIES_LIMIT}") || []
    end

    def matches_query?(story, query)
      story['title'].to_s.downcase.match?(query) ||
        story['text'].to_s.downcase.match?(query)
    end
  end
end
