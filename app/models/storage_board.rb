class StorageBoard < ApplicationRecord
  belongs_to :storage
  belongs_to :user, optional: true

  has_many :storage_board_comments, dependent: :destroy
  has_many :storage_board_recommend_logs, dependent: :destroy
  has_many_attached :images, dependent: :destroy

  validate :nickname_inspection, on: %i[update]
  validate :password_minimum_length, on: %i[update]

  def self.fetch_with_options(options = {})
    storage = Storage.find_by(id: options[:storage_id], is_active: true)
    storage = Storage.find_by(path: options[:storage_id], is_active: true) if storage.blank?
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if storage.blank?

    storage_boards = storage.active_boards

    storage_boards = storage_boards.where('nickname like :search', {
      search: "%#{options[:nickname]}%"
    }) if options[:nickname].present?

    storage_boards = storage_boards.where('subject like :search', {
      search: "%#{options[:subject]}%"
    }) if options[:subject].present?

    storage_boards = storage_boards.where('content like :search', {
      search: "%#{options[:content]}%"
    }) if options[:content].present?

    if options[:orderBy].present?
      storage_boards = storage_boards.order(id: :desc) if options[:orderBy] == 'latest'
      storage_boards = storage_boards.order(id: :asc) if options[:orderBy] == 'old'
      storage_boards = storage_boards.where(is_popular: true).order(created_at: :desc) if options[:orderBy] == 'popular'
    end

    storage_boards
  end

  def self.fetch_by_cached_with_options(options = {})
    storage = Storage.find_active_by_cached(options[:storage_id])

    redis_key = "storages-#{storage[:id]}-boards-#{options.values.to_s}"
    namespace = "storages-#{storage[:id]}-boards"

    storage_boards = Rails.cache.read(redis_key, namespace: namespace)
    pagination = Rails.cache.read("#{redis_key}/pagination", namespace: namespace)

    if storage_boards.blank? || pagination.blank?
      storage_boards = StorageBoard.where(storage_id: storage[:id], is_draft: false, is_active: true)

      storage_boards = storage_boards.where('nickname like :search', {
        search: "%#{options[:nickname]}%"
      }) if options[:nickname].present?

      storage_boards = storage_boards.where('subject like :search', {
        search: "%#{options[:subject]}%"
      }) if options[:subject].present?

      storage_boards = storage_boards.where('content like :search', {
        search: "%#{options[:content]}%"
      }) if options[:content].present?

      if options[:orderBy].present?
        storage_boards = storage_boards.order(id: :desc) if options[:orderBy] == 'latest'
        storage_boards = storage_boards.order(id: :asc) if options[:orderBy] == 'old'
        storage_boards = storage_boards.where(is_popular: true).order(created_at: :desc) if options[:orderBy] == 'popular'
      end

      storage_boards = storage_boards.page(options[:page]).per(options[:per] || 10)

      Rails.cache.write(redis_key, ActiveModelSerializers::SerializableResource.new(
        storage_boards,
        each_serializer: StorageBoardSerializer
      ).as_json, expires_in: 5.minutes, namespace: namespace)
      Rails.cache.write("#{redis_key}/pagination", PaginationSerializer.new(storage_boards).as_json, expires_in: 5.minutes, namespace: namespace)

      storage_boards = Rails.cache.read(redis_key, namespace: namespace)
      pagination = Rails.cache.read("#{redis_key}/pagination", namespace: namespace)
    end

    {
      boards: storage_boards,
      pagination: pagination
    }
  end

  def self.find_active_with_options(options = {})
    options = options.merge(is_draft: false, is_active: true)

    storage_board = find_by(options)
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    storage_board
  end

  def self.find_active_by_cached(options = {})
    options = options.merge(is_draft: false, is_active: true)

    redis_key = "storages-#{options[:storage_id]}-boards-#{options[:id]}"
    namespace = "storages-#{options[:storage_id]}-boards-detail"

    storage_board = Rails.cache.read(redis_key, namespace: namespace)

    if storage_board.blank?
      storage_board = find_by(options)
      raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

      Rails.cache.write(redis_key, StorageBoardSerializer.new(storage_board).as_json, namespace: namespace)
      storage_board = Rails.cache.read(redis_key, namespace: namespace)
    end

    storage_board
  end

  def self.find_with_options(options = {})
    options = options.merge(is_active: true, is_member: true) if options[:user].present?
    options = options.merge(is_active: true, is_member: false) if options[:user].blank?

    storage_board = find_by(options)
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    storage_board
  end

  def self.find_for_non_member(options = {})
    options = options.merge(user_id: nil, is_active: true, is_member: false)

    storage_board = find_by(options.except(:password))
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    if BCrypt::Password.new(storage_board.password) != options[:password].to_s
      raise Errors::BadRequest.new(code: 'COC027', message: 'Password do not match.')
    end

    storage_board
  end

  def self.create_draft(options = {})
    options = options.merge(user_id: options[:user].id, is_member: true) if options[:user].present?
    options = options.except(:user)

    create!(options)
  end

  def self.update_for_member(options = {})
    storage_board = find_with_options(options.except(:subject, :content, :description))
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    content_html = Nokogiri::HTML.parse(options[:content])
    options = options.merge(has_image: false, has_video: false)
    %w[youtube kakao].each do |name|
      options = options.merge(has_video: true) if content_html.css('iframe').attr('src').to_s.index(name).present?
    end
    options = options.merge(has_video: true) if content_html.css('video').present?
    options = options.merge(has_image: true) if content_html.css('img').present? || storage_board.images.attached?

    options = options.except(:user)
    options = options.merge(is_draft: false)

    storage_board.update(options).inspect
    storage_board
  end

  def self.update_for_non_member(options = {})
    storage_board = find_with_options(options.except(:nickname, :password, :subject, :content, :description))
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    if storage_board.password.present? && BCrypt::Password.new(storage_board.password) != options[:password]
      raise Errors::BadRequest.new(code: 'COC027', message: 'Password do not match.')
    end

    options[:password] = BCrypt::Password.create(options[:password])

    content_html = Nokogiri::HTML.parse(options[:content])
    options = options.merge(has_image: false, has_video: false)
    %w[youtube kakao].each do |name|
      options = options.merge(has_video: true) if content_html.css('iframe').attr('src').to_s.index(name).present?
    end
    options = options.merge(has_video: true) if content_html.css('video').present?
    options = options.merge(has_image: true) if content_html.css('img').present? || storage_board.images.attached?

    options = options.except(:nickname) if storage_board.nickname.present?
    options = options.except(:password) if storage_board.password.present?
    options = options.merge(is_draft: false)

    storage_board.update(options).inspect
    storage_board
  end

  def self.destroy_for_member(options = {})
    storage_board = find_with_options(options)
    storage_board.images.purge

    storage_board.destroy
  end

  def self.destroy_for_non_member(options = {})
    storage_board = find_for_non_member(options)
    storage_board.images.purge

    storage_board.destroy
  end

  def self.update_active_view_count(options = {})
    storage_board = find_active_with_options(options)
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    storage_board.increment!(:view_count, 1)
  end

  def self.update_recommend_with_options(options = {})
    storage_board = find_active_with_options(options.except(:user, :type, :request))

    storage_board_recommend_log = StorageBoardRecommendLog.find_by(
      storage_board: storage_board,
      created_ip: options[:request].headers['CF-Connecting-IP'] || options[:request].remote_ip
    )

    if storage_board_recommend_log.present?
      if storage_board_recommend_log.log_type == 'thumb_up'
        raise Errors::BadRequest.new(code: 'COC028', message: 'Already have a recommended record, type is thumb_up.')
      end
      if storage_board_recommend_log.log_type == 'thumb_down'
        raise Errors::BadRequest.new(code: 'COC029', message: 'Already have a recommended record, type is thumb_down.')
      end
    end

    storage_board.increment!(:thumb_up, 1) if options[:type] == 0
    storage_board.increment!(:thumb_down, 1) if options[:type] == 1

    StorageBoardRecommendLog.create!(
      storage_board_id: storage_board.id,
      user_id: options[:user].present? ? options[:user].id : nil,
      log_type: options[:type],
      created_ip: options[:request].remote_ip,
      created_user_agent: options[:request].user_agent
    )

    storage_board
  end

  def active_comments
    storage_board_comments.where(is_active: true)
  end

  def thumbnail_url
    first_files_url_of(images)
  end

  def last_image_url
    last_files_url_of(images)
  end

  def comment_count
    storage_board_comments.size
  end

  def reply_count
    StorageBoardCommentReply.where(storage_board_comment_id: storage_board_comments.map(&:id)).size
  end

  private

  def nickname_inspection
    if !is_member && nickname.present?
      regex = /[ㄱ-ㅎㅏ-ㅣ가-힣a-zA-Z0-9]{2,10}/
      special_regex = "[ !@\#$%^&*(),.?\":{}|<>]"

      raise Errors::BadRequest.new(code: 'COC001', message: 'nickname is invalid') unless nickname =~ regex
      raise Errors::BadRequest.new(code: 'COC001', message: 'nickname is invalid') if nickname.length > 10
      raise Errors::BadRequest.new(code: 'COC001', message: 'nickname is invalid') if nickname.match(special_regex)
    end
  end

  def password_minimum_length
    if !is_member && password.present? && password.length < 7
      raise Errors::BadRequest.new(code: 'COC004', message: 'Password must be at least 7 characters long.')
    end
  end
end
