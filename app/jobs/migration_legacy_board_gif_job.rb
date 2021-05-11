class MigrationLegacyBoardGifJob < ApplicationJob
  queue_as :migration_legacy_board_gif

  require 'open-uri'

  def perform(*args)
    StorageBoard.all.find_each(batch_size: 1000).each do |storage_board|
      parse_storage_board_content = Nokogiri::HTML::DocumentFragment.parse(storage_board.content)

      has_image = false
      has_video = false

      images = parse_storage_board_content.css('img')

      has_image = true if images.present?

      %w[youtube kakao].each do |name|
        has_video = true if parse_storage_board_content.css('iframe').attr('src').to_s.index(name).present?
        has_video = true if parse_storage_board_content.css('embed').attr('src').to_s.index(name).present?
      end

      gif_images = parse_storage_board_content.css('video')
      gif_images.remove_attr('onmousedown')
      gif_images.remove_attr('data-src')

      gif_images.each do |gif_image|
        begin
          src = gif_image.css('source').attr('src')

          if src.present? && src.to_s.index('api.cocstorage').present?
            download_image = URI.open(src)
            storage_board.images.attach(io: download_image, filename: SecureRandom.urlsafe_base64(20))

            gif_image.at('source')['src'] = storage_board.last_image_url
            gif_image.at('source')['alt'] = 'Board Img'
          end
        rescue
          next
        end
      end if gif_images.present?

      has_video = true if gif_images.present?

      storage_board.update(content: parse_storage_board_content, has_image: has_image, has_video: has_video)
    end
  end
end
