class GoogleIssueKeywordScarpJob < ApplicationJob
  queue_as :google_issue_keyword_scrap

  require 'open-uri'

  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.2 Safari/605.1.15'

  def perform(*args)
    response = URI.open('https://trends.google.co.kr/trends/trendingsearches/daily/rss?geo=KR', 'User-Agent' => USER_AGENT)
    issue_keywords = Nokogiri::XML(response)

    begin
      if response.status.first.to_i < 400
        issue_keywords.css('item').each do |issue_keyword|
          keyword = issue_keyword.css('title').text

          db_issue_keyword = IssueKeyword.find_by_keyword(keyword)

          if db_issue_keyword.present?
            db_issue_keyword.increment!(:count, 1)
          else
            new_issue_keyword = IssueKeyword.create(
              keyword: keyword,
              source: 'google',
              original: keyword,
              count: 10,
              created_at: issue_keyword.css('pubDate').text,
              updated_at: issue_keyword.css('pubDate').text
            )

            new_issue_keyword_image_url = issue_keyword.css('ht|picture').text

            news_items = issue_keyword.css('ht|news_item')

            news_items.each do |news_item|
              title = CGI.unescapeHTML(news_item.css('ht|news_item_title').text)
              description = CGI.unescapeHTML(news_item.css('ht|news_item_snippet').text)
              url = CGI.unescapeHTML(news_item.css('ht|news_item_url').text)
              source = CGI.unescapeHTML(news_item.css('ht|news_item_source').text)

              new_issue_keyword_content = IssueKeywordContent.create(
                issue_keyword_id: new_issue_keyword.id,
                title: title,
                description: description,
                url: url,
                source: source
              )

              download_image = URI.open(new_issue_keyword_image_url, 'User-Agent' => USER_AGENT)
              new_issue_keyword_content.image.attach(io: download_image, filename: SecureRandom.urlsafe_base64(20))
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
