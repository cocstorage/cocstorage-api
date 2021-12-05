module Scraper
  require 'open-uri'
  require 'selenium-webdriver'
  require 'webdrivers'

  CHROME_DRIVER_PATH = ENV['CHROME_DRIVER_PATH']
  USER_AGENT = [
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.2 Safari/605.1.15',
    'Mozilla/5.0 (X11; CrOS x86_64 13597.94.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.186 Safari/537.36',
    'Mozilla/5.0 (X11; CrOS x86_64 14150.74.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.114 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.2 Safari/605.1.15'
  ]
  IMAGE_USER_AGENT = [
    'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.128 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 11; SAMSUNG SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/15.0 Chrome/90.0.4430.210 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 9; SM-G955F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36',
    'Mozilla/5.0 (Linux; Android 9; SM-G955F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1 Mobile/15E148 Safari/604.1'
  ]

  def self.init_selenium_web_driver(type)
    if type === "chrome"
      Selenium::WebDriver::Chrome::Service.driver_path = CHROME_DRIVER_PATH

      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument('--headless')
      options.add_argument('--no-sandbox')
      options.add_argument('--disable-dev-shm-usage')
      options.add_argument("--user-agent=#{USER_AGENT.sample}")

      browser = Selenium::WebDriver.for :chrome, options: options

      browser
    end
  end

  class Dcinside
    def initialize(browser, storage)
      @browser = browser
      @storage = storage
      @has_image = false
      @has_video = false
      @referrer = "https://gall.dcinside.com/board/lists?id=#{@storage.code}"
      @url = "https://gall.dcinside.com/board/lists?id=#{@storage.code}&exception_mode=recommend"
      @url = "https://gall.dcinside.com/mgallery/board/lists?id=#{@storage.code}&exception_mode=recommend" if @storage.storage_type == "minor"
    end

    def get_has_image
      @has_image
    end

    def get_has_video
      @has_video
    end

    def get_scrap_boards_html
      response = URI.open(@url, 'User-Agent' => USER_AGENT.sample, 'Referrer' => @referrer)

      if response.status.first.to_i < 400
        html = Nokogiri::HTML(response)

        html.css('.ub-content.us-post')
      else
        []
      end
    end

    def set_scrap_code_and_board_url(scrap_code)
      @scrap_code = scrap_code
      @board_url = "https://gall.dcinside.com/board/view/?id=#{@storage.code}&no=#{@scrap_code}&page=1"
      @board_url = "https://gall.dcinside.com/mgallery/board/view/?id=#{@storage.code}&no=#{@scrap_code}&exception_mode=recommend&page=1" if @storage.storage_type == "minor"
    end

    def get_scrap_board_options
      response = URI.open(@board_url, 'User-Agent' => USER_AGENT.sample, 'Referrer' => @url)

      if response.status.first.to_i < 400
        board_detail = Nokogiri::HTML(response)

        subject = board_detail.css('.title_subject').text
        nickname = board_detail.css('.gall_writer.ub-writer').first['data-nick']
        ip = board_detail.css('.gall_writer.ub-writer').first['data-ip']
        content = board_detail.css('.write_div')

        if subject.blank? || content.blank?
          Rails.logger.debug "Title or content does not exist in (#{@storage.code}-#{@scrap_code})"
        end

        options = {
          storage_id: @storage.id,
          scrap_code: @scrap_code,
          source_code: @storage.code,
          nickname: nickname,
          created_ip: ip,
          subject: subject,
          content: content,
          description: content.text,
          is_member: true,
          is_draft: true,
          is_active: false
        }

        %w[youtube kakao].each do |name|
          @has_video = true if content.css('iframe').attr('src').to_s.index(name).present?
          @has_video = true if content.css('embed').present?
          @has_video = true if content.css('video').present?
        end

        options = options.merge(has_video: @has_video)

        options
      end
    end

    def get_content_html(content)
      Nokogiri::HTML::DocumentFragment.parse(content)
    end

    def has_video_iframe(content_html)
      iframes = content_html.css('iframe')
      has_video_iframe = false

      iframes.each do |iframe|
        if iframe.attr('src').to_s.index('dcinside').present?
          has_video_iframe = true
          break
        end
      end

      has_video_iframe
    end

    def get_content_html_with_videos(content_html, storage_board)
      begin
        @browser.get(@board_url)

        iframes = @browser.find_element(css: '.write_div').find_elements(css: 'iframe')
        iframes.each do |iframe|
          id = iframe.attribute('id')

          @browser.switch_to.frame(iframe)

          if id === "pollFrame"
            @browser.switch_to.default_content

            @browser.execute_script("
                      const element = document.getElementById('#{id}')
                      if (element) {
                          element.outerHTML = '현재 지원되지 않는 기능입니다.';
                      }
                    ")

            content_html = Nokogiri::HTML::DocumentFragment.parse(@browser.find_element(css: '.write_div').attribute('innerHTML'))
          else
            source = @browser.find_element(css: "source")
            next if source.blank?

            src = source.attribute('src')
            @browser.switch_to.default_content

            download_image = URI.open(src, 'User-Agent' => IMAGE_USER_AGENT.sample, 'Referrer' => @board_url)
            storage_board.images.attach(io: download_image, filename: SecureRandom.urlsafe_base64(20))

            src = storage_board.last_image_url

            @browser.execute_script("
                      const element = document.getElementById('#{id}')
                      const video = document.createElement('video');
                      video.setAttribute('controls', 'controls');
                      video.setAttribute('playsinline', 'playsinline');
                      video.setAttribute('controlslist', 'nodownload');
                      const source = document.createElement('source');
                      source.src = '#{src}';
                      source.type = 'video/mp4';
                      if (element) {
                          video.innerHTML = source.outerHTML;
                          element.outerHTML = video.outerHTML;
                      }
                    ")

            @has_video = true
            content_html = Nokogiri::HTML::DocumentFragment.parse(@browser.find_element(css: '.write_div').attribute('innerHTML'))
          end
        end
      rescue => e
        Rails.logger.debug "Error scraping and upload videos in iframe (#{@storage.code}-#{@scrap_code})"
        Rails.logger.debug e
      end

      content_html
    end

    def upload_images(content_html, storage_board)
      images = content_html.css('img')
      images.remove_attr('style')
      images.remove_attr('onclick')

      images.each do |image|
        begin
          download_image = URI.open(image['src'], 'User-Agent' => IMAGE_USER_AGENT.sample, 'Referrer' => @board_url)
          storage_board.images.attach(io: download_image, filename: SecureRandom.urlsafe_base64(20))

          image['src'] = storage_board.last_image_url
          image['alt'] = 'Board Img'

          @has_image = true
        rescue => e
          Rails.logger.debug "Error scraping and upload image (#{@storage.code}-#{@scrap_code})"
          Rails.logger.debug e
          next
        end
      end if images.present?
    end

    def upload_gif_images(content_html, storage_board)
      gif_images = content_html.css('video')
      gif_images.remove_attr('class')
      gif_images.remove_attr('poster')
      gif_images.remove_attr('onmousedown')
      gif_images.remove_attr('data-src')

      gif_images.each do |gif_image|
        begin
          download_image = URI.open(gif_image.css('source').attr('src'), 'User-Agent' => IMAGE_USER_AGENT.sample, 'Referrer' => @board_url)
          storage_board.images.attach(io: download_image, filename: SecureRandom.urlsafe_base64(20))

          gif_image.at('source')['src'] = storage_board.last_image_url
          gif_image.at('source')['alt'] = 'Board Img'

          @has_video = true
        rescue => e
          Rails.logger.debug "Error scraping and upload gif_image (#{@storage.code}-#{@scrap_code})"
          Rails.logger.debug e
          next
        end
      end if gif_images.present?
    end

    def scrap_and_create_comments(storage_board)
      storage_board_comment_url = "https://gall.dcinside.com/board/view/?id=#{@storage.code}&no=#{@scrap_code}&t=cv&exception_mode=recommend&page=1"
      storage_board_comment_url = "https://gall.dcinside.com/mgallery/board/view/?id=#{@storage.code}&no=#{@scrap_code}&t=cv&exception_mode=recommend&page=1" if @storage.storage_type == "minor"

      begin
        @browser.get(storage_board_comment_url)

        pages = @browser.find_element(css: '.cmt_paging').find_elements(:xpath => "*")
        page_nums = pages.map { |page| page.text.to_i }

        page_nums.each do |page_num|
          begin
            if page_num > 1
              @browser.execute_script("viewComments(#{page_num}, 'D')")
              sleep 1.5
            end

            # Comments & Replies
            @browser.find_element(css: '.cmt_list').find_elements(:xpath => "*").each do |comment|
              comment_data_no = comment.attribute('id').split('_').last

              next if comment_data_no.to_s == "0"

              if comment_data_no.present?
                begin
                  comment_writer = comment.find_element(css: '.gall_writer.ub-writer')
                  comment_content = comment.find_element(css: '.usertxt.ub-word')
                rescue
                  next
                end

                storage_board_comment = StorageBoardComment.create(
                  storage_board_id: storage_board.id,
                  nickname: comment_writer.attribute('data-nick'),
                  content: comment_content.text,
                  created_ip: comment_writer.attribute('data-ip'),
                  is_member: 1
                )

                # Replies
                @browser.find_elements(id: "reply_list_#{comment_data_no}").each do |reply_list|
                  reply_list.find_elements(:xpath => "*").each do |reply|
                    begin
                      reply_writer = reply.find_element(css: '.gall_writer.ub-writer')
                      reply_content = reply.find_element(css: '.usertxt.ub-word')
                    rescue
                      next
                    end

                    StorageBoardCommentReply.create(
                      storage_board_comment_id: storage_board_comment.id,
                      nickname: reply_writer.attribute('data-nick'),
                      content: reply_content.text,
                      created_ip: reply_writer.attribute('data-ip'),
                      is_member: 1
                    )
                  end
                end
              end
            end
          rescue => e
            Rails.logger.debug "Error scraping comments or replies (#{@storage.code}-#{@scrap_code})"
            Rails.logger.debug e
            next
          end
        end
      rescue => e
        Rails.logger.debug "Error scraping comments pagination (#{@storage.code}-#{@scrap_code})"
        Rails.logger.debug e
      end
    end
  end
end