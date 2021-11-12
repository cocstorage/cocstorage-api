class StorageBoardScrapJob < ApplicationJob
  queue_as :storage_board_scrap

  require 'open-uri'
  require 'selenium-webdriver'
  require 'webdrivers'

  def perform(*args)
    user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.2 Safari/605.1.15'
    image_user_agent = 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.128 Mobile Safari/537.36'

    Selenium::WebDriver::Chrome::Service.driver_path = ENV['CHROME_DRIVER_PATH']

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument("--user-agent=#{user_agent}")

    browser = Selenium::WebDriver.for :chrome, options: options

    storage_category = StorageCategory.find_by(code: 'CCA000')

    begin
      storage_category.storages.each do |storage|
        referrer = "https://gall.dcinside.com/board/lists?id=#{storage.code}"

        url = "https://gall.dcinside.com/board/lists?id=#{storage.code}&exception_mode=recommend"
        url = "https://gall.dcinside.com/mgallery/board/lists?id=#{storage.code}&exception_mode=recommend" if storage.storage_type == "minor"

        sleep 1

        response = URI.open(url, 'User-Agent' => user_agent, 'Referrer' => referrer)
        next if response.status.first.to_i >= 400

        html = Nokogiri::HTML(response)

        posts = html.css('.ub-content.us-post')

        post_already_exist_check_count = 0

        posts.each do |post|
          break if post_already_exist_check_count >= 7

          scrap_code = post['data-no']
          post_url = "https://gall.dcinside.com/board/view/?id=#{storage.code}&no=#{scrap_code}&page=1"
          post_url = "https://gall.dcinside.com/mgallery/board/view/?id=#{storage.code}&no=#{scrap_code}&exception_mode=recommend&page=1" if storage.storage_type == "minor"

          sleep 3

          response = URI.open(post_url, 'User-Agent' => user_agent, 'Referrer' => url)
          next if response.status.first.to_i >= 400

          post = Nokogiri::HTML(response)

          subject = post.css('.title_subject').text
          nickname = post.css('.gall_writer.ub-writer').first['data-nick']
          ip = post.css('.gall_writer.ub-writer').first['data-ip']
          content = post.css('.write_div')

          if subject.blank? || content.blank?
            logger.debug "Title or content does not exist in (#{storage.code}-#{scrap_code})"
          end

          options = {
            storage_id: storage.id,
            scrap_code: scrap_code,
            source_code: storage.code,
            nickname: nickname,
            created_ip: ip,
            subject: subject,
            content: content,
            description: content.text,
            is_member: true,
            is_draft: false
          }

          %w[youtube kakao].each do |name|
            options = options.merge(has_video: true) if content.css('iframe').attr('src').to_s.index(name).present?
            options = options.merge(has_video: true) if content.css('embed').present?
            options = options.merge(has_video: true) if content.css('video').present?
          end

          unless StorageBoard.where(storage_id: storage.id, scrap_code: scrap_code).exists?
            storage_board = StorageBoard.create(options)

            parse_storage_board_content = Nokogiri::HTML::DocumentFragment.parse(storage_board.content)

            iframes = parse_storage_board_content.css('iframe')
            has_video_iframe = false
            has_video = false

            iframes.each do |iframe|
              if iframe.attr('src').to_s.index('dcinside').present?
                has_video_iframe = true
                break
              end
            end

            if has_video_iframe
              begin
                browser.get(post_url)

                iframes = browser.find_element(css: '.write_div').find_elements(css: 'iframe')
                iframes.each do |iframe|
                  id = iframe.attribute('id')

                  browser.switch_to.frame(iframe)

                  if id === "pollFrame"
                    browser.switch_to.default_content

                    browser.execute_script("
                    const element = document.getElementById('#{id}')
                    if (element) {
                        element.outerHTML = '현재 지원되지 않는 기능입니다.';
                    }
                  ")
                  else
                    source = browser.find_element(css: "source")
                    next if source.blank?

                    src = source.attribute('src')
                    browser.switch_to.default_content

                    download_image = URI.open(src, 'User-Agent' => image_user_agent, 'Referrer' => post_url)
                    storage_board.images.attach(io: download_image, filename: SecureRandom.urlsafe_base64(20))

                    src = storage_board.last_image_url

                    browser.execute_script("
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

                    has_video = true
                    parse_storage_board_content = Nokogiri::HTML::DocumentFragment.parse(browser.find_element(css: '.write_div').attribute('innerHTML'))
                  end
                end
              rescue
                next
              end
            end

            images = parse_storage_board_content.css('img')
            images.remove_attr('style')
            images.remove_attr('onclick')

            images.each do |image|
              begin
                download_image = URI.open(image['src'], 'User-Agent' => image_user_agent, 'Referrer' => post_url)
                storage_board.images.attach(io: download_image, filename: SecureRandom.urlsafe_base64(20))

                image['src'] = storage_board.last_image_url
                image['alt'] = 'Board Img'
              rescue
                next
              end
            end if images.present?

            has_image = true if images.present?

            gif_images = parse_storage_board_content.css('video')
            gif_images.remove_attr('class')
            gif_images.remove_attr('poster')
            gif_images.remove_attr('onmousedown')
            gif_images.remove_attr('data-src')

            gif_images.each do |gif_image|
              begin
                download_image = URI.open(gif_image.css('source').attr('src'), 'User-Agent' => image_user_agent, 'Referrer' => post_url)
                storage_board.images.attach(io: download_image, filename: SecureRandom.urlsafe_base64(20))

                gif_image.at('source')['src'] = storage_board.last_image_url
                gif_image.at('source')['alt'] = 'Board Img'
              rescue
                next
              end
            end if gif_images.present?

            storage_board.update(content: parse_storage_board_content, has_image: has_image, has_video: has_video)

            storage_board_comment_url = "https://gall.dcinside.com/board/view/?id=#{storage.code}&no=#{scrap_code}&t=cv&exception_mode=recommend&page=1"
            storage_board_comment_url = "https://gall.dcinside.com/mgallery/board/view/?id=#{storage.code}&no=#{scrap_code}&t=cv&exception_mode=recommend&page=1" if storage.storage_type == "minor"

            begin
              browser.get(storage_board_comment_url)

              pages = browser.find_element(css: '.cmt_paging').find_elements(:xpath => "*")
              page_nums = pages.map { |page| page.text.to_i }

              page_nums.each do |page_num|
                if page_num > 1
                  browser.execute_script("viewComments(#{page_num}, 'D')")
                  sleep 1.5
                end

                # Comments & Replies
                browser.find_element(css: '.cmt_list').find_elements(:xpath => "*").each do |comment|
                  begin
                    comment_data_no = comment.attribute('id').split('_').last

                    if comment_data_no.present?
                      comment_writer = comment.find_element(css: '.gall_writer.ub-writer')
                      comment_content = comment.find_element(css: '.usertxt.ub-word')

                      storage_board_comment = StorageBoardComment.create(
                        storage_board_id: storage_board.id,
                        nickname: comment_writer.attribute('data-nick'),
                        content: comment_content.text,
                        created_ip: comment_writer.attribute('data-ip'),
                        is_member: 1
                      )

                      # Replies
                      browser.find_elements(id: "reply_list_#{comment_data_no}").each do |reply_list|
                        reply_list.find_elements(:xpath => "*").each do |reply|
                          reply_writer = reply.find_element(css: '.gall_writer.ub-writer')
                          reply_content = reply.find_element(css: '.usertxt.ub-word')

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
                  rescue
                    next
                  end
                end
              end
            rescue
              next
            end
          else
            post_already_exist_check_count += 1
          end
        end
      end
    rescue
      browser.quit
    end

    browser.quit
  end
end
