class StorageBoard < ApplicationRecord
  belongs_to :storage
  belongs_to :user
end
