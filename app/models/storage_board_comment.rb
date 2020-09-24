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

  def self.create_with_options(options = {})
    storage = Storage.find_activation(options[:storage_id])
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage.blank?

    StorageBoard.find_activation_with_options(
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

  private

  def password_minimum_length
    if !is_member && password.present? && password.length < 7
      raise Errors::BadRequest.new(code: 'COC004', message: 'Password must be at least 7 characters long.')
    end
  end
end
