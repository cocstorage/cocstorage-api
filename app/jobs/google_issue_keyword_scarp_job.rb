class GoogleIssueKeywordScarpJob < ApplicationJob
  queue_as :google_issue_keyword_scrap

  require 'open-uri'

  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.2 Safari/605.1.15'

  def perform(*args)
    response = URI.open('https://trends.google.co.kr/trends/trendingsearches/daily/rss?geo=KR', 'User-Agent' => USER_AGENT)
    issue_keywords = Nokogiri::XML(response)

    begin
      if response.status.first.to_i < 400
        issue_keywords = issue_keywords.css('item')
        issue_keywords_size = issue_keywords.size

        issue_keywords.each_with_index do |issue_keyword, index|
          keyword = issue_keyword.css('title').text

          db_issue_keyword = IssueKeyword.find_by_keyword(keyword)

          if db_issue_keyword.present?
            db_issue_keyword.update(count: db_issue_keyword.count + (50 + (issue_keywords_size - index)))

            storage = Storage.find_by_issue_keyword_id(db_issue_keyword.id)
            storage.update(updated_at: DateTime.now) if storage.present?
          else
            db_issue_keyword = IssueKeyword.create(
              keyword: keyword,
              source: 'google',
              original: keyword,
              count: 50 + (issue_keywords_size - index)
            )

            path = keyword.gsub(" ", "-").strip

            unless Storage.where(issue_keyword_id: db_issue_keyword.id).exists?
              storage_category = StorageCategory.find_by_code("CCB001")

              Storage.create(
                storage_category_id: storage_category.id,
                user_id: 2,
                path: path,
                name: keyword,
                description: "현재 이슈가 되고 있는 '#{keyword}'에 관한 얘기를 나누는 공간입니다.",
                code: keyword,
                storage_type: 2,
                issue_keyword_id: db_issue_keyword.id
              )
            end
          end
        end
      else
        Rails.logger.debug "Error scraping google trend keywords"
      end
    rescue => e
      Rails.logger.debug "Error scraping google trend keywords"
      Rails.logger.debug e
    end
  end
end
