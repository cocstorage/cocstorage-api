class NoticeComment < ApplicationRecord
  belongs_to :notice
  belongs_to :user, optional: true

  validate :nickname_inspection, on: %i[create]
  validate :password_minimum_length, on: %i[create]

  def self.fetch_with_options(options = {})
    notice = Notice.find_by(id: options[:notice_id], is_draft: false, is_active: true)
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if notice.blank?

    notice_comments = notice.active_comments

    if options[:orderBy]
      notice_comments = notice_comments.order(created_at: :desc) if options[:orderBy] == 'latest'
      notice_comments = notice_comments.order(created_at: :asc) if options[:orderBy] == 'old'
    end

    notice_comments
  end

  def self.create_with_options(options = {})
    options = options.merge(user_id: options[:user].id, is_member: true) if options[:user].present?
    options = options.merge(user_id: nil, is_member: false) if options[:user].blank?

    options = options.except(:user)

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
