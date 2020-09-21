class StorageBoardComment < ApplicationRecord
  belongs_to :storage_board
  belongs_to :user

  def self.create_with_options(options = {})
    storage = Storage.find_activation(options[:storage_id])
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage.blank?

    storage_board = StorageBoard.find_activation_with_options(
      options.except(:user, :storage_board_id, :content, :created_ip, :created_user_agent)
    )
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_board.blank?

    options = options.merge(user_id: options[:user].id) if options[:user].present?
    options = options.except(:user, :storage_id)

    create(options)
  end
end
