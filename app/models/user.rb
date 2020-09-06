class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_one :user_email_access_log

  enum role: %w[user admin]

  validate :email_format
  validate :password_minimum_length
  validate :password_special_char

  def self.create_user(params)
    user = create(params)
    user.update(nickname: "닉네임#{user.id}")
    user.create_user_email_access_log(params)

    user
  end

  def create_user_email_access_log(options = {})
    data = {
      user_id: id,
      access_uuid: SecureRandom.hex(20),
      access_expired_at: DateTime.current.in_time_zone('Asia/Seoul') + 1.day,
      created_ip: options[:created_ip]
    }

    UserEmailAccessLog.create(data)
  end

  def email_format
    raise Errors::BadRequest.new(code: 'COC002', message: 'email is invalid') unless email =~ URI::MailTo::EMAIL_REGEXP
  end

  def password_minimum_length
    if password.length < 7
      raise Errors::BadRequest.new(code: 'COC004', message: 'password must be at least 7 characters long')
    end
  end

  def password_special_char
    special = "@?<>',?[]}{=-)(*&^%$#`~{}!"
    regex = /[#{special.gsub(/./) { |char| "\\#{char}" }}]/
    unless password =~ regex
      raise Errors::BadRequest.new(code: 'COC005', message: 'password must contain special character')
    end
  end
end
