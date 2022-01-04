class CommunityIssueKeywordScrapJob < ApplicationJob
  queue_as :community_issue_keyword_scrap

  require 'open-uri'

  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.2 Safari/605.1.15'

  def perform(*args)
    response = URI.open('https://www.dcinside.com', 'User-Agent' => USER_AGENT)

    begin
      if response.status.first.to_i < 400
        html = Nokogiri::HTML(response)

        issue_keywords = html.css('.day_issue_list li')

        issue_keywords.each do |issue_keyword|
          keyword = issue_keyword.text.strip

          db_issue_keyword = IssueKeyword.find_by_keyword(keyword)

          if db_issue_keyword.blank?
            db_issue_keyword = IssueKeyword.create(
              keyword: keyword,
              source: 'dcinside',
              original: keyword,
              count: 1
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

        boards = html.css('.rank_list.gall.g_1 li')

        boards.each do |board|
          board_url = board.css('a').attr('href')

          response = URI.open(board_url, 'User-Agent' => USER_AGENT)

          if response.status.first.to_i < 400
            html = Nokogiri::HTML(response)
            posts = html.css('.ub-content.us-post')

            posts.each do |post|
              title = post.css('.gall_tit.ub-word > a:first-child').text.strip
              keywords = title.split(" ")

              keywords.each do |keyword|
                new_keyword = keyword.gsub(/[을를이가은는로으로]/, "")

                db_issue_keyword = IssueKeyword.find_by_keyword(new_keyword)

                if db_issue_keyword.present?
                  db_issue_keyword.increment!(:count, 1)
                end
              end
            end
          else
            Rails.logger.debug "Error scraping dcinside board keywords"
          end
        end
      else
        Rails.logger.debug "Error scraping dcinside issue, boards keywords"
      end
    rescue => e
      Rails.logger.debug "Error scraping dcinside issue, boards keywords"
      Rails.logger.debug e
    end
  end
end
