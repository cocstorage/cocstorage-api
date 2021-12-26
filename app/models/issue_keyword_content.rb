class IssueKeywordContent < ApplicationRecord
  belongs_to :issue_keyword
  has_one_attached :image

  def thumbnail_url
    file_url_of(image)
  end
end
