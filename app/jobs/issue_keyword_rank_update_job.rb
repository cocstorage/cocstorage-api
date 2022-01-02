class IssueKeywordRankUpdateJob < ApplicationJob
  queue_as :issue_keyword_rank_update

  def perform(*args)
    last_issue_keyword_rank = IssueKeywordRank.last

    if last_issue_keyword_rank.blank?
      date = DateTime.now.strftime("%Y-%m-%d %R")
      issue_keywords = IssueKeyword.all.limit(10).order(count: :desc)

      issue_keyword_ranks = []

      issue_keywords.each_with_index do |issue_keyword, index|
        issue_keyword_ranks << {
          number: index + 1,
          keyword_id: issue_keyword.id,
          keyword: issue_keyword.keyword,
          path: issue_keyword.storage.path,
          isUp: false,
          isDown: false,
          isNew: true
        }
      end

      IssueKeywordRank.create(
        date: date,
        ranks: issue_keyword_ranks
      )
    else
      date = DateTime.now
      diff_minute = (((last_issue_keyword_rank.date - date) / 1.minute).round).abs

      return false if diff_minute < 5

      issue_keywords = IssueKeyword.all.limit(10).order(count: :desc)
      new_issue_keyword_ranks = []

      issue_keywords.each_with_index do |issue_keyword, index|
        change_rank = check_change_rank(last_issue_keyword_rank.ranks, index + 1, issue_keyword.id)

        new_issue_keyword_ranks << {
          number: index + 1,
          keyword_id: issue_keyword.id,
          keyword: issue_keyword.keyword,
          path: issue_keyword.storage.path,
          isUp: change_rank == 'up',
          isDown: change_rank == 'down',
          isNew: change_rank == 'new'
        }
      end

      IssueKeywordRank.create(
        date: date,
        ranks: new_issue_keyword_ranks
      )
    end
  end

  def check_change_rank(last_ranks, number, keyword_id)
    result = 'new'

    last_ranks.each_with_index do |last_rank|
      next if last_rank['keyword_id'] != keyword_id
      if last_rank['number'] > number
        result = 'up'
      elsif last_rank['number'] < number
        result = 'down'
      else
        result = 'none'
      end
    end

    result
  end
end
