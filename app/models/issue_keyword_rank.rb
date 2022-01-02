class IssueKeywordRank < ApplicationRecord
  def self.fetch_by_cached
    redis_key = 'latest_issue_keyword_rank'

    issue_keyword_rank = Rails.cache.read(redis_key)

    if issue_keyword_rank.blank?
      Rails.cache.write(redis_key, IssueKeywordRank.last, expires_in: 5.minutes)

      issue_keyword_rank = Rails.cache.read(redis_key)
    end

    issue_keyword_rank
  end
end
