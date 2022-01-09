class ZumIssueKeywordScarpJob < ApplicationJob
  queue_as :zum_issue_keyword_scarp_job

  require 'open-uri'

  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.2 Safari/605.1.15'

  def perform(*args)
    response = URI.open('https://search.zum.com/search.zum?method=uni&option=accu&qm=f_typing&rd=1&query=%EC%98%A4%EB%8A%98%20%EB%82%A0%EC%94%A8', 'User-Agent' => USER_AGENT)

    begin
      if response.status.first.to_i < 400
        html = Nokogiri::HTML(response)

        issue_wrap = html.css('#issue_wrap')
        issue_keyword_list = issue_wrap.css('.ranking.is_rolling')

        issue_keyword_list.each do |issue_keyword_wrap|
          issue_keywords = issue_keyword_wrap.css('li')

          issue_keywords_size = 10

          issue_keywords.each do |issue_keyword|
            keyword = issue_keyword.css('.txt').first.text
            number = issue_keyword.css('.num').first.text.to_i

            db_issue_keyword = IssueKeyword.find_by_keyword(keyword)

            if db_issue_keyword.present?
              count = db_issue_keyword.count + (issue_keywords_size - number)
              count = issue_keywords_size - number unless db_issue_keyword.updated_at.today?

              db_issue_keyword.update(count: count)

              storage = Storage.find_by_issue_keyword_id(db_issue_keyword.id)
              storage.update(updated_at: DateTime.now) if storage.present?
            else
              db_issue_keyword = IssueKeyword.create(
                keyword: keyword,
                source: 'zum',
                original: keyword,
                count: 10 + (issue_keywords_size - number)
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
        end
      else
        Rails.logger.debug "Error scraping zum issue keywords"
      end
    rescue => e
      Rails.logger.debug "Error scraping zum issue keywords"
      Rails.logger.debug e
    end
  end
end
