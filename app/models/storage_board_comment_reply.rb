class StorageBoardCommentReply < ApplicationRecord
  belongs_to :storage_board_comment
  belongs_to :user, optional: true

  validate :nickname_inspection, on: %i[create]
  validate :password_minimum_length, on: %i[create]

  def self.create_with_options(options = {})
    if options[:user].present?
      options = options.merge(user_id: options[:user].id, is_member: true)
      options = options.except(:user)
    end

    create!(options)
  end

  def self.destroy_for_member(options = {})
    options = options.merge(is_active: true, is_member: true)

    storage_board_comment_reply = find_by(options)
    if storage_board_comment_reply.blank?
      raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.")
    end

    storage_board_comment_reply.destroy
  end

  def self.destroy_for_non_member(options = {})
    options = options.merge(user_id: nil, is_active: true, is_member: false)

    storage_board_comment_reply = find_by(options.except(:password))
    if storage_board_comment_reply.blank?
      raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.")
    end

    if storage_board_comment_reply.password.to_s != options[:password].to_s
      raise Errors::BadRequest.new(code: 'COC027', message: 'Password do not match.')
    end

    storage_board_comment_reply.destroy
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
