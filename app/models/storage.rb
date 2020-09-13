class Storage < ApplicationRecord
  belongs_to :storage_category
  belongs_to :user
end
