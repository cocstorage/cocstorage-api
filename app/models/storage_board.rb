class StorageBoard < ApplicationRecord
  belongs_to :storage
  belongs_to :user, optional: true

  has_many :storage_board_comments
  has_many :storage_board_recommend_logs
  has_many_attached :images

  validate :password_minimum_length, on: %i[update]

  def self.fetch_with_options(options = {})
    storage = Storage.find_by(id: options[:storage_id], is_active: true)
    storage = Storage.find_by(path: options[:storage_id], is_active: true) if storage.blank?
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage.blank?

    storage_boards = storage.active_boards
    storage_boards = storage_boards.where('subject like ?', "#{options[:subject]}%") if options[:subject].present?
    storage_boards = storage_boards.where('content like ?', "#{options[:content]}%") if options[:content].present?
    storage_boards = storage_boards.where('nickname like ?', "#{options[:nickname]}%") if options[:nickname].present?

    if options[:orderBy].present?
      storage_boards = storage_boards.order(created_at: :desc) if options[:orderBy] == 'latest'
      storage_boards = storage_boards.order(created_at: :asc) if options[:orderBy] == 'old'
    end

    storage_boards
  end

  def self.find_activation_with_options(options = {})
    options = options.merge(storage_id: options[:storage_id], is_draft: false, is_active: true)
    storage_board = find_by(options)
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    storage_board
  end

  def self.find_with_options(options = {})
    options = options.merge(storage_id: options[:storage_id], is_active: true)
    options = options.merge(is_member: true) if options[:user].present?
    options = options.merge(user_id: nil, is_member: false) unless options[:user].present?

    storage_board = find_by(options)
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    storage_board
  end

  def self.find_for_non_member(options = {})
    options = options.merge(storage_id: options[:storage_id], user_id: nil, is_active: true, is_member: false)
    storage_board = find_by(options.except(:password))
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    if storage_board.password.to_s != options[:password].to_s
      raise Errors::BadRequest.new(code: 'COC027', message: 'Password do not match.')
    end

    storage_board
  end

  def self.create_draft(options = {})
    storage = Storage.find_activation(options[:storage_id])
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage.blank?

    options = options.merge(storage_id: storage.id)
    options = options.merge(user_id: options[:user].id, is_member: true) if options[:user].present?
    options = options.except(:user)

    create(options)
  end

  def self.update_for_member(options = {})
    storage_board = find_with_options(options.except(:subject, :content))
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    content_html = Nokogiri::HTML.parse(options[:content])
    options = options.merge(description: content_html.text)
    options = options.merge(has_image: false, has_video: false)
    %w[youtube kakao].each do |name|
      options = options.merge(has_video: true) if content_html.css('iframe').attr('src').to_s.index(name).present?
    end
    options = options.merge(has_video: true) if content_html.css('video').present?
    options = options.merge(has_image: true) if content_html.css('img').present?

    options = options.except(:user)
    options = options.merge(is_draft: false)

    storage_board.update(options).inspect
    storage_board
  end

  def self.update_for_non_member(options = {})
    storage_board = find_with_options(options.except(:nickname, :password, :subject, :content))
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    if storage_board.password.to_s != options[:password].to_s
      raise Errors::BadRequest.new(code: 'COC027', message: 'Password do not match.')
    end

    content_html = Nokogiri::HTML.parse(options[:content])
    options = options.merge(description: content_html.text)
    options = options.merge(has_image: false, has_video: false)
    %w[youtube kakao].each do |name|
      options = options.merge(has_video: true) if content_html.css('iframe').attr('src').to_s.index(name).present?
    end
    options = options.merge(has_video: true) if content_html.css('video').present?
    options = options.merge(has_image: true) if content_html.css('img').present?

    options = options.except(:nickname) if storage_board.nickname.present?
    options = options.except(:password) if storage_board.password.present?
    options = options.merge(is_draft: false)

    storage_board.update(options).inspect
    storage_board
  end

  def self.destroy_for_member(options = {})
    storage_board = find_with_options(options)
    storage_board.destroy
  end

  def self.destroy_for_non_member(options = {})
    storage_board = find_for_non_member(options)
    storage_board.destroy
  end

  def self.update_activation_view_count(options = {})
    storage_board = find_by(id: options[:id], storage_id: options[:storage_id], is_draft: false, is_active: true)
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    storage_board.increment!(:view_count, 1)
  end

  def self.update_recommend_for_member(options = {})
    storage_board = find_activation_with_options(options.except(:user, :type, :request))

    storage_board_recommend_log = StorageBoardRecommendLog.find_by(
      storage_board: storage_board,
      user: options[:user]
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
    StorageBoardRecommendLog.create(
      storage_board_id: storage_board.id,
      user_id: options[:user].id,
      log_type: options[:type],
      created_ip: options[:request].remote_ip,
      created_user_agent: options[:request].user_agent
    )

    storage_board
  end

  def self.update_recommend_for_non_members(options = {})
    storage_board = find_activation_with_options(options.except(:type, :request))

    storage_board_recommend_log = StorageBoardRecommendLog.find_by(
      storage_board: storage_board,
      created_ip: options[:request].remote_ip
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
    StorageBoardRecommendLog.create(
      storage_board_id: storage_board.id,
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

  private

  def password_minimum_length
    if !is_member && password.present? && password.length < 7
      raise Errors::BadRequest.new(code: 'COC004', message: 'Password must be at least 7 characters long.')
    end
  end
end
