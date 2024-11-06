class HomeController < ApplicationController
  CACHE_EXPIRY = 5.minutes

  def index
    @stories = if params[:q].blank?
                 Rails.cache.fetch('top_stories', expires_in: CACHE_EXPIRY) do
                   story_ids = HackerNewsService.fetch_top_stories
                   stories = HackerNewsService.fetch_story_details(story_ids)
                   stories.sort_by { |story| -story['time'].to_i }
                 end
               else
                 Rails.cache.fetch("search_stories_#{params[:q]}", expires_in: 1.minute) do
                   HackerNewsService.search_stories(params[:q].to_s.downcase)
                 end
               end
  end

  def comments
    @story = HackerNewsService.fetch_story_details(params[:id])
    @comments = Rails.cache.fetch("comments_#{params[:id]}", expires_in: CACHE_EXPIRY) do
      HackerNewsService.fetch_comments(@story['kids']) if @story['kids']
    end
  end
end
