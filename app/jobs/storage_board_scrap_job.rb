class StorageBoardScrapJob < ApplicationJob
  queue_as :storage_board_scrap

  require 'open-uri'
  require 'selenium-webdriver'
  require 'webdrivers'

  def perform(*args)
    user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.2 Safari/605.1.15'
    image_user_agent = 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.128 Mobile Safari/537.36'

    storage_category = StorageCategory.find_by(code: "CCA000")

    storage_category.storages.each do |storage|
      referrer = "https://gall.dcinside.com/board/lists?id=#{storage.code}"
      url = "https://gall.dcinside.com/board/lists?id=#{storage.code}&exception_mode=recommend"
      create_new_storage_board = false

      sleep 1

      response = URI.open(url, 'User-Agent' => user_agent, 'Referrer' => referrer)
      next if response.status.first.to_i != 200

      html = Nokogiri::HTML(response)

      posts = html.css('.ub-content.us-post')

      posts.each do |post|
        scrap_code = post['data-no']
        post_url = "https://gall.dcinside.com/board/view/?id=#{storage.code}&no=#{scrap_code}&page=1"

        sleep 3

        response = URI.open(post_url, 'User-Agent' => user_agent, 'Referrer' => url)
        next if response.status.first.to_i != 200

        post = Nokogiri::HTML(response)

        subject = post.css('.title_subject').text
        nickname = post.css('.gall_writer.ub-writer').first['data-nick']
        ip = post.css('.gall_writer.ub-writer').first['data-ip']
        content = post.css('.write_div')

        next if subject.blank? || content.blank?

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

        unless StorageBoard.where(scrap_code: scrap_code).exists?
          storage_board = StorageBoard.create(options)
          create_new_storage_board = true

          parse_storage_board_content = Nokogiri::HTML::DocumentFragment.parse(storage_board.content)

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

          storage_board.update(content: parse_storage_board_content, has_image: has_image)

          storage_board_comment_url = "https://gall.dcinside.com/board/view/?id=#{storage.code}&no=#{scrap_code}&t=cv&exception_mode=recommend&page=1"

          Selenium::WebDriver::Chrome::Service.driver_path = ENV['CHROME_DRIVER_PATH']

          options = Selenium::WebDriver::Chrome::Options.new
          options.add_argument("--headless")
          options.add_argument("--no-sandbox")
          options.add_argument("--disable-dev-shm-usage")
          options.add_argument("--user-agent=#{user_agent}")

          browser = Selenium::WebDriver.for :chrome, options: options

          begin
            browser.get(storage_board_comment_url)

            pages = browser.find_element(css: '.cmt_paging').find_elements(:xpath => "*")
            page_nums = pages.map { |page| page.text.to_i }

            page_nums.each do |page_num|
              if page_num > 1
                browser.execute_script("viewComments(#{page_num}, 'D')")
                sleep 3
              end

              # Comments & Replies
              browser.find_element(css: '.cmt_list').find_elements(:xpath => "*").each do |comment|
                begin
                  comment_data_no = comment.attribute('id').split('_').last
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
                rescue
                  next
                end
              end
            end
          ensure
            browser.quit
          end
        end

        if create_new_storage_board
          namespace = "storage-#{storage.id}-boards"
          Rails.cache.clear(namespace: namespace)
        end
      end
    end
  end
end
