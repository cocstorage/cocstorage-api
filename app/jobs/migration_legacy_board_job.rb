class MigrationLegacyBoardJob < ApplicationJob
  queue_as :migration_legacy_board

  def perform(*args)
    ActiveRecord::Base.establish_connection Rails.env.to_sym
    StorageBoard.destroy_all

    %w[ib_board stream_board extra_board baseball_board].each do |reg_code|
      begin
        storage_id = get_storage_id_by_reg_code(reg_code)
        next if storage_id.blank?

        ActiveRecord::Base.establish_connection(
          { :adapter => 'mysql2',
            :database => 'collect',
            :host => '106.10.41.71',
            :username => 'root',
            :password => 'dnflwlqdb@' }
        )

        create_new_storage_board = false

        boards = ActiveRecord::Base.connection.execute("SELECT data_no, nickname, ip, subject, content, original_category_id, register_date FROM #{reg_code}").map do |board|
          data_no = board[0]
          nickname = board[1]
          ip = board[2]
          subject = board[3]
          content = board[4]
          original_category_id = board[5]
          register_date = board[6]

          options = {
            storage_id: get_storage_id_by_reg_code(reg_code),
            scrap_code: data_no,
            source_code: original_category_id,
            nickname: nickname,
            created_ip: ip,
            subject: subject,
            content: content,
            is_member: true,
            is_draft: false,
            created_at: register_date
          }

          options
        end

        ActiveRecord::Base.establish_connection Rails.env.to_sym

        full_sanitizer = Rails::Html::FullSanitizer.new

        boards.each do |board|
          storage_board = StorageBoard.create(board)
          create_new_storage_board = true

          parse_board_content = Nokogiri::HTML::DocumentFragment.parse(storage_board.content)

          images = parse_board_content.css('img')
          images.remove_attr('style')
          images.remove_attr('onclick')

          has_image = false
          has_video = false

          images.each do |image|
            begin
              download_image = URI.open(image['src'])
              storage_board.images.attach(io: download_image, filename: SecureRandom.urlsafe_base64(20))

              image['src'] = storage_board.last_image_url
              image['alt'] = 'Board Img'
            rescue
              next
            end
          end if images.present?

          %w[youtube kakao].each do |name|
            has_video = true if parse_board_content.css('iframe').attr('src').to_s.index(name).present?
          end

          has_image = true if images.present?

          storage_board.update(
            content: parse_board_content,
            description: full_sanitizer.sanitize(parse_board_content.to_s).strip,
            has_image: has_image,
            has_video: has_video
          )
        end

        if create_new_storage_board
          namespace = "storage-#{storage_id}-boards"
          Rails.cache.clear(namespace: namespace)
        end
      rescue
        next
      end
    end

    ActiveRecord::Base.establish_connection Rails.env.to_sym
  end

  private

  def get_storage_id_by_reg_code(reg_code)
    ActiveRecord::Base.establish_connection Rails.env.to_sym

    if reg_code == 'stream_board'
      storage = Storage.find_by_code('stream')
    elsif reg_code == 'extra_board'
      storage = Storage.find_by_code('extra')
    elsif reg_code == 'baseball_board'
      storage = Storage.find_by_code('baseball_new10')
    else
      storage = Storage.find_by_code('ib_new2')
    end

    storage.id if storage.present?
  end
end
