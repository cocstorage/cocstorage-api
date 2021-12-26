class AddOmissionColumnsToIssueKeywordContent < ActiveRecord::Migration[6.0]
  def change
    add_column :issue_keyword_contents, :title, :string
    add_column :issue_keyword_contents, :description, :string
    add_column :issue_keyword_contents, :content_type, :integer, default: 0
  end
end
