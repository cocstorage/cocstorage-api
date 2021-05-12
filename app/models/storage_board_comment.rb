class StorageBoardComment < ApplicationRecord
  belongs_to :storage_board
  belongs_to :user, optional: true

  has_many :storage_board_comment_replies, dependent: :destroy

  validate :nickname_inspection, on: %i[create]
  validate :password_minimum_length, on: %i[create]

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

  def self.fetch_by_cached_with_options(options = {})
    storage_board = StorageBoard.find_active_by_cached(storage_id: options[:storage_id], id: options[:storage_board_id])

    redis_key = "storages-#{options[:storage_id]}-boards-#{options[:storage_board_id]}-comments-#{options.values.to_s}"
    namespace = "storages-#{options[:storage_id]}-boards-#{options[:storage_board_id]}-comments"

    storage_board_comments = Rails.cache.read(redis_key, namespace: namespace)
    pagination = Rails.cache.read("#{redis_key}/pagination", namespace: namespace)

    if storage_board_comments.blank? || pagination.blank?
      storage_board_comments = StorageBoardComment.where(storage_board_id: storage_board[:id])

      if options[:orderBy]
        storage_board_comments = storage_board_comments.order(created_at: :desc) if options[:orderBy] == 'latest'
        storage_board_comments = storage_board_comments.order(created_at: :asc) if options[:orderBy] == 'old'
      end

      storage_board_comments = storage_board_comments.page(options[:page]).per(options[:per] || 20)

      Rails.cache.write(redis_key, ActiveModelSerializers::SerializableResource.new(
        storage_board_comments,
        each_serializer: StorageBoardCommentSerializer
      ).as_json, namespace: namespace)
      Rails.cache.write("#{redis_key}/pagination", PaginationSerializer.new(storage_board_comments).as_json, namespace: namespace)

      storage_board_comments = Rails.cache.read(redis_key, namespace: namespace)
      pagination = Rails.cache.read("#{redis_key}/pagination", namespace: namespace)
    end

    {
      comments: storage_board_comments,
      pagination: pagination
    }
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
