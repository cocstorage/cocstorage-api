class StorageBoardScrapJob < ApplicationJob
  queue_as :storage_board_scrap

  require 'modules/scraper'

  def perform(*args)
    browser = Scraper.init_selenium_web_driver("chrome")

    begin
      ActiveRecord::Base.connection_pool.with_connection do
        storage_category = StorageCategory.find_by(code: 'CCA000')

        storage_category.storages.each do |storage|
          dcinside_scrapper = Scraper::Dcinside.new(browser, storage)

          boards = dcinside_scrapper.get_scrap_boards_html
          already_exist_check_count = 0

          boards.each do |board|
            break if already_exist_check_count >= 7

            dcinside_scrapper.set_scrap_code_and_board_url(board['data-no'])

            sleep 3

            scrap_board_options = dcinside_scrapper.get_scrap_board_options

            next if scrap_board_options.blank?

            if StorageBoard.where(storage_id: scrap_board_options[:storage_id], scrap_code: scrap_board_options[:scrap_code]).exists?
              already_exist_check_count += 1
              next
            end

            storage_board = StorageBoard.create(scrap_board_options)

            content_html = dcinside_scrapper.get_content_html(storage_board.content)

            has_video_iframe = dcinside_scrapper.has_video_iframe(content_html)

            content_html = dcinside_scrapper.get_content_html_with_videos(content_html, storage_board) if has_video_iframe

            dcinside_scrapper.upload_images(content_html, storage_board)
            dcinside_scrapper.upload_gif_images(content_html, storage_board)

            has_image = dcinside_scrapper.get_has_image
            has_video = dcinside_scrapper.get_has_video

            dcinside_scrapper.scrap_and_create_comments(storage_board)

            storage_board.update(content: content_html, has_image: has_image, has_video: has_video, is_draft: false, is_active: true)
          end
        end
      end
    ensure
      browser.quit
    end
  end
end
