class StorageUserRole < ApplicationRecord
  belongs_to :storage
  belongs_to :user

  enum role: %w[admin manager]
end
