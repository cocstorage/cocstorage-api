class AddOmissionColumnsToIssueKeywordContent < ActiveRecord::Migration[6.0]
  def change
    add_column :issue_keyword_contents, :title, :string
    add_column :issue_keyword_contents, :description, :string
  end
end
