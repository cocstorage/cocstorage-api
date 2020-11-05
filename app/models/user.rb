class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_many :storages, dependent: :destroy

  has_one :user_email_access_log, dependent: :destroy

  has_one_attached :avatar, dependent: :destroy

  enum role: %w[member admin]

  validate :email_inspection, on: :create
  validate :name_inspection, on: %i[create update]
  validate :nickname_inspection, on: :update
  validate :password_minimum_length, on: %i[create update]
  validate :password_special_char, on: %i[create update]
  validate :avatar_inspection, on: %i[create update]

  def self.create_with_options(options = {})
    user = create(options)
    user.update(nickname: "닉네임#{user.id}#{SecureRandom.hex(2)}")
    user.create_user_email_access_log(options)

    user
  end

  def self.update_with_options(options = {})
    if options[:nickname].present?
      compare_user = find_by_nickname(options[:nickname])
      if compare_user.present? && compare_user.id != options[:user].id
        raise Errors::BadRequest.new(code: 'COC015', message: 'nickname is exist')
      end
    end

    user = find(options[:user].id)
    if options[:password].present?
      if BCrypt::Password.new(user.encrypted_password) != options[:current_password]
        raise Errors::BadRequest.new(code: 'COC027', message: 'Password do not match.')
      end
    end

    user.update(options.except(:user, :current_password)).inspect

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
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if user_email_access_log.blank?

    user = find(user_email_access_log.user_id)
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if user.blank?
    raise Errors::BadRequest.new(code: 'COC007', message: 'Account is already authenticated.') if user.is_authenticated

    if user_email_access_log.access_uuid.length > 40
      raise Errors::BadRequest.new(code: 'COC001', message: 'uuid is invalid')
    end
    if user_email_access_log.access_expired_at < DateTime.current
      raise Errors::BadRequest.new(code: 'COC017', message: 'Access is expired.')
    end

    user.update(is_authenticated: true)

    user
  end

  def self.withdrawal_reservation_with_options(options = {})
    user = find(options[:user].id)
    if user.withdrawaled_at.present?
      raise Errors::BadRequest.new(code: 'COC019', message: 'This account is already in the process of withdrawal.')
    end

    if BCrypt::Password.new(user.encrypted_password) != options[:password]
      raise Errors::BadRequest.new(code: 'COC027', message: 'Password do not match.')
    end

    user.update(withdrawaled_at: DateTime.current + 7.day)

    user
  end

  def avatar_url
    file_url_of(avatar)
  end

  def send_reset_password_and_token
    raw, enc = Devise.token_generator.generate(self.class, :reset_password_token)

    self.password               = raw
    self.reset_password_token   = enc
    self.reset_password_sent_at = Time.now.utc
    save(validate: false)

    UserPasswordResetMailerJob.perform_later(self, raw)

    self
  end

  def jwt_payload
    { 'pyl' => { id: id, nickname: nickname, avatarUrl: avatar_url, role: role, isAuthenticated: is_authenticated } }
  end

  private

  def email_inspection
    raise Errors::BadRequest.new(code: 'COC001', message: 'email is invalid') unless email =~ Devise::email_regexp
    raise Errors::BadRequest.new(code: 'COC003', message: 'email already exists') if User.find_by(email: email).present?
  end

  def name_inspection
    if name.present?
      normal_regex = /[가-힣]{2,5}/
      special_regex = "[ !@\#$%^&*(),.?\":{}|<>]"

      raise Errors::BadRequest.new(code: 'COC001', message: 'name is invalid') unless name =~ normal_regex
      raise Errors::BadRequest.new(code: 'COC001', message: 'name is invalid') if name.length > 5
      raise Errors::BadRequest.new(code: 'COC001', message: 'name is invalid') if name.match(special_regex)
    end
  end

  def nickname_inspection
    if nickname.present?
      regex = /[ㄱ-ㅎㅏ-ㅣ가-힣a-zA-Z0-9]{2,10}/
      special_regex = "[ !@\#$%^&*(),.?\":{}|<>]"

      raise Errors::BadRequest.new(code: 'COC001', message: 'nickname is invalid') unless nickname =~ regex
      raise Errors::BadRequest.new(code: 'COC001', message: 'name is invalid') if nickname.length > 10
      raise Errors::BadRequest.new(code: 'COC001', message: 'name is invalid') if nickname.match(special_regex)

      user = User.find_by_nickname(nickname)
      if user.present? && user.nickname != nickname
        raise Errors::BadRequest.new(code: 'COC015', message: 'nickname is exist')
      end
    end
  end

  def password_minimum_length
    if password.present? && password.length < 7
      raise Errors::BadRequest.new(code: 'COC004', message: 'Password must be at least 7 characters long.')
    end
  end

  def password_special_char
    if password.present?
      special = "@?<>',?[]}{=-)(*&^%$#`~{}!"
      regex = /[#{special.gsub(/./) { |char| "\\#{char}" }}]/
      unless password =~ regex
        raise Errors::BadRequest.new(code: 'COC005', message: 'Password must contain special character.')
      end
    end
  end

  def avatar_inspection
    if avatar.attached? && !avatar.content_type.in?(%w[image/png image/gif image/jpg image/jpeg])
      Errors::BadRequest.new(code: 'COC016', message: "#{avatar.content_type} is unacceptable image format")
    end
  end
end
