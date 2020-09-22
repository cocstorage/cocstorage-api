class StorageBoardComment < ApplicationRecord
  belongs_to :storage_board
  belongs_to :user, optional: true

  validate :password_minimum_length, on: %i[create]

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

    options = options.merge(user_id: options[:user].id) if options[:user].present?
    options = options.except(:user, :storage_id)

    puts options

    create(options)
  end

  private

  def password_minimum_length
    if !is_member && password.present? && password.length < 7
      raise Errors::BadRequest.new(code: 'COC004', message: 'Password must be at least 7 characters long.')
    end
  end
end
