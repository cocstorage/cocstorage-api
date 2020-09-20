class StorageUserRole < ApplicationRecord
  belongs_to :storage
  belongs_to :user

  enum role: %w[manager admin]
end
