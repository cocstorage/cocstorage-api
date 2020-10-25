class StorageBoardComment < ApplicationRecord
  belongs_to :storage_board
  belongs_to :user, optional: true

  has_many :storage_board_comment_replies

  validate :nickname_inspection, on: %i[create]
  validate :password_minimum_length, on: %i[create]

  before_destroy :destroy_storage_board_comment_replies

  def self.fetch_with_options(options = {})
    storage_board = StorageBoard.find_by(id: options[:storage_board_id], is_draft: false, is_active: true)
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    storage_board_comments = storage_board.active_comments

    if options[:orderBy]
      storage_board_comments = storage_board_comments.order(created_at: :desc) if options[:orderBy] == 'latest'
      storage_board_comments = storage_board_comments.order(created_at: :asc) if options[:orderBy] == 'old'
    end

    storage_board_comments
  end

  def self.find_with_options(options = {})
    options = options.merge(user_id: options[:user].id, is_member: true) if options[:user].present?
    options = options.merge(user_id: nil, is_member: false) if options[:user].blank?

    options = options.except(:user, :storage_id)

    storage_board_comment = find_by(options.except(:password))
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if storage_board_comment.blank?

    storage_board_comment
  end

  def self.create_with_options(options = {})
    options = options.merge(user_id: options[:user].id, is_member: true) if options[:user].present?
    options = options.merge(user_id: nil, is_member: false) if options[:user].blank?

    options = options.except(:user, :storage_id)

    options[:password] = BCrypt::Password.create(options[:password]) if options[:password].present?

    create!(options)
  end

  def self.destroy_for_member(options = {})
    storage_board_comment = find_with_options(options)
    storage_board_comment.destroy
  end

  def self.destroy_for_non_member(options = {})
    storage_board_comment = find_with_options(options)

    if BCrypt::Password.new(storage_board_comment.password) != options[:password].to_s
      raise Errors::BadRequest.new(code: 'COC027', message: 'Password do not match.')
    end

    storage_board_comment.destroy
  end

  def destroy_storage_board_comment_replies
    storage_board_comment_replies.destroy_all
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
