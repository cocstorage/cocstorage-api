class StorageBoardRecommendLog < ApplicationRecord
  belongs_to :storage_board
  belongs_to :user, optional: true

  enum log_type: %w[thumb_up thumb_down]
end
