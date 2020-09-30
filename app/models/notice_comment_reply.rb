class NoticeCommentReply < ApplicationRecord
  belongs_to :notice_comment
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
