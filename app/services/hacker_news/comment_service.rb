module HackerNews
  class CommentService < BaseClient
    MAX_DEPTH = 2

    def fetch_comments(comment_ids, depth = 1)
      return [] if comment_ids.blank? || depth > MAX_DEPTH

      comment_ids.map do |comment_id|
        fetch_comment_with_replies(comment_id, depth)
      end.compact
    end

    private

    def fetch_comment_with_replies(comment_id, depth)
      comment = make_request("#{api_url}/item/#{comment_id}.json")
      return if comment.nil? || comment['deleted'] || comment['text']&.split(/\s+/)&.count.to_i <= 20

      if comment['kids'].present?
        replies = fetch_comments(comment['kids'], depth + 1)
        comment['replies'] = replies unless replies.empty?
      end

      comment
    end

    def api_url
      'https://hacker-news.firebaseio.com/v0'
    end
  end
end
