class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_one :user_email_access_log
  has_one_attached :profileImage

  enum role: %w[user admin]

  validate :email_format, on: :create
  validate :password_minimum_length, on: %i[create update]
  validate :password_special_char, on: %i[create update]

  def self.create_with_options(options)
    user = create(options)
    user.update(nickname: "닉네임#{user.id}#{SecureRandom.hex(2)}")
    user.create_user_email_access_log(options)

    user
  end

  def create_user_email_access_log(options = {})
    data = {
      user_id: id,
      access_uuid: SecureRandom.hex(20),
      access_expired_at: DateTime.current + 1.day,
      created_ip: options[:created_ip]
    }

    UserEmailAccessLog.create(data)
  end

  def self.authentication(uuid)
    user_email_access_log = UserEmailAccessLog.find_by(access_uuid: uuid)
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource") if user_email_access_log.blank?

    user = find(user_email_access_log.user_id)
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource") if user.blank?
    raise Errors::BadRequest.new(code: 'COC007', message: 'Account is already authenticated') if user.is_authenticated

    if user_email_access_log.access_uuid.length > 40
      raise Errors::BadRequest.new(code: 'COC001', message: 'uuid is invalid')
    end
    if user_email_access_log.access_expired_at < DateTime.current
      raise Errors::BadRequest.new(code: 'COC006', message: 'Access is expired')
    end

    user.update(is_authenticated: true, is_active: true)

    user
  end

  def self.withdrawal_reservation(id)
    user = find(id)
    if user.withdrawaled_at.present?
      raise Errors::BadRequest.new(code: 'COC019', message: 'This account is already in the process of withdrawal')
    end

    user.update(withdrawaled_at: DateTime.current + 7.day)
    user
  end

  def profile_image_url
    file_url_of(profileImage)
  end

  private

  def email_format
    raise Errors::BadRequest.new(code: 'COC002', message: 'email is invalid') unless email =~ Devise::email_regexp
  end

  def password_minimum_length
    if password.present? && password.length < 7
      raise Errors::BadRequest.new(code: 'COC004', message: 'Password must be at least 7 characters long')
    end
  end

  def password_special_char
    if password.present?
      special = "@?<>',?[]}{=-)(*&^%$#`~{}!"
      regex = /[#{special.gsub(/./) { |char| "\\#{char}" }}]/
      unless password =~ regex
        raise Errors::BadRequest.new(code: 'COC005', message: 'Password must contain special character')
      end
    end
  end

  def profile_image_type
    if profileImage.attached? && !profileImage.content_type.in?(%w[image/png image/gif image/jpg image/jpeg])
      Errors::BadRequest.new(code: 'COC016', message: "#{profileImage.content_type} is unacceptable image format")
    end
  end
end
