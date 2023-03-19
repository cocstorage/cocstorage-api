class StorageBoardScrapJob < ApplicationJob
  queue_as :storage_board_scrap

  require 'modules/scraper'

  def perform(*args)
    storage = Storage.find(38)

    fahumor_scrapper = Scraper::Fahumor.new(storage)
    boards = fahumor_scrapper.get_scrap_boards_html
    already_exist_check_count = 0

    boards.each do |board|
      break if already_exist_check_count >= 3

      fahumor_scrapper.set_scrap_code_and_board_url(board['href'])

      sleep 3

      scrap_board_options = fahumor_scrapper.get_scrap_board_options

      next if scrap_board_options.blank?

      if StorageBoard.where(storage_id: scrap_board_options[:storage_id], scrap_code: scrap_board_options[:scrap_code]).exists?
        already_exist_check_count += 1
        next
      end

      storage_board = StorageBoard.create(scrap_board_options)

      content_html = fahumor_scrapper.get_content_html(storage_board.content)

      fahumor_scrapper.check_has_video_iframe(content_html)
      fahumor_scrapper.upload_images(content_html, storage_board)
      fahumor_scrapper.upload_gif_images(content_html, storage_board)

      has_image = fahumor_scrapper.get_has_image
      has_video = fahumor_scrapper.get_has_video

      storage_board.attach_thumbnail if has_image

      storage_board.update(content: content_html, has_image: has_image, has_video: has_video, is_draft: false, is_active: true)
    end
  end
end
