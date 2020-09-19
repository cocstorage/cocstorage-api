class StorageBoard < ApplicationRecord
  belongs_to :storage
  belongs_to :user, optional: true

  has_many_attached :images

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
    storage = Storage.find(options[:storage_id])
    options = options.merge(storage_id: storage.id, is_draft: false, is_active: true)
    storage_board = find_by(options)
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    storage_board
  end

  def self.find_by_with_options(options = {})
    storage = Storage.find(options[:storage_id])
    options = options.merge(storage_id: storage.id, is_active: true)
    options = options.merge(is_member: true) if options[:user].present?
    options = options.merge(is_member: false) unless options[:user].present?
    storage_board = find_by(options)
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    storage_board
  end

  def self.create_draft_with_options(options = {})
    storage = Storage.find(options[:storage_id])
    options = options.merge(storage_id: storage.id)
    options = options.merge(user_id: options[:user].id, is_member: true) if options[:user].present?
    StorageBoard.create(options.except(:user))
  end

  def self.update_activation_view_count_with_options(options = {})
    storage = Storage.find(options[:storage_id])
    storage_board = find_by(id: options[:id], storage_id: storage.id, is_draft: false, is_active: true)
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    storage_board.increment!(:view_count, 1)
  end

  def thumbnail_url
    first_files_url_of(images)
  end

  def last_image_url
    last_files_url_of(images)
  end
end
