class IssueKeywordRankCleanJob < ApplicationJob
  queue_as :issue_keyword_rank_clean

  def perform(*args)
    IssueKeyword.update_all(count: 0)
  end
end
