class HomeController < ApplicationController
  CACHE_EXPIRY = 5.minutes

  def index
    Rails.cache.delete('top_stories') if params[:refresh].present?
    @stories = if params[:q].blank?
                 Rails.cache.fetch('top_stories', expires_in: CACHE_EXPIRY) do
                   story_service = HackerNews::StoryService.new
                   story_ids = story_service.fetch_top_stories
                   stories = story_service.fetch_story_details(story_ids)
                   stories.sort_by { |story| -story['time'].to_i }
                 end
               else
                 Rails.cache.fetch("search_stories_#{params[:q]}", expires_in: 1.minute) do
                   HackerNews::StoryService.new.search_stories(params[:q].to_s.downcase)
                 end
               end
  end

  def comments
    story_service = HackerNews::StoryService.new
    comment_service = HackerNews::CommentService.new

    @story = story_service.fetch_story_details(params[:id])
    @comments = Rails.cache.fetch("comments_#{params[:id]}", expires_in: CACHE_EXPIRY) do
      comment_service.fetch_comments(@story['kids']) if @story['kids']
    end
  end
end
