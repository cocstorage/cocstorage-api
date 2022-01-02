class AddKeywordIndexInIssueKeyword < ActiveRecord::Migration[6.0]
  def change
    add_index :issue_keywords, :keyword, unique: true
  end
end
