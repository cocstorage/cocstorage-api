class AddIssueKeywordToStorage < ActiveRecord::Migration[6.0]
  def change
    add_reference :storages, :issue_keyword, null: true, foreign_key: true
  end
end
