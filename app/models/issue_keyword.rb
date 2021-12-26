class IssueKeyword < ApplicationRecord
  has_many :issue_keyword_contents, dependent: :destroy
end
