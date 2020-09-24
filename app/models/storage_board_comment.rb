class StorageBoardComment < ApplicationRecord
  belongs_to :storage_board
  belongs_to :user, optional: true

  validate :password_minimum_length, on: %i[create]

  def self.fetch_with_options(options = {})
    storage_board = StorageBoard.find_by(id: options[:storage_board_id], is_active: true)
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    storage_board_comments = storage_board.active_comments

    if options[:orderBy]
      storage_board_comments = storage_board_comments.order(created_at: :desc) if options[:orderBy] == 'latest'
      storage_board_comments = storage_board_comments.order(created_at: :asc) if options[:orderBy] == 'old'
    end

    storage_board_comments
  end

  def self.find_with_options(options = {})
    StorageBoard.find_active_with_options(
      options.except(:storage_board_id, :user, :password).merge(id: options[:storage_board_id])
    )

    options = options.merge(user_id: options[:user].id, is_member: true) if options[:user].present?
    options = options.merge(user_id: nil, is_member: false) if options[:user].blank?

    options = options.except(:user, :storage_id)

    storage_board_comment = find_by(options.except(:password))
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_board_comment.blank?

    storage_board_comment
  end

  def self.create_with_options(options = {})
    storage = Storage.find_active(options[:storage_id])
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage.blank?

    StorageBoard.find_active_with_options(
      options.except(
        :storage_board_id,
        :user,
        :nickname,
        :password,
        :content,
        :created_ip,
        :created_user_agent
      ).merge(id: options[:storage_board_id])
    )

    options = options.merge(user_id: options[:user].id, is_member: true) if options[:user].present?
    options = options.except(:user, :storage_id)

    create(options)
  end

  def self.destroy_for_member(options = {})
    storage = Storage.find_active(options[:storage_id])
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage.blank?

    storage_board_comment = find_with_options(options)

    storage_board_comment.destroy
  end

  def self.destroy_for_non_member(options = {})
    storage = Storage.find_active(options[:storage_id])
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage.blank?

    storage_board_comment = find_with_options(options)

    if storage_board_comment.password.to_s != options[:password].to_s
      raise Errors::BadRequest.new(code: 'COC027', message: 'Password do not match.')
    end

    storage_board_comment.destroy
  end

  private

  def password_minimum_length
    if !is_member && password.present? && password.length < 7
      raise Errors::BadRequest.new(code: 'COC004', message: 'Password must be at least 7 characters long.')
    end
  end
end
