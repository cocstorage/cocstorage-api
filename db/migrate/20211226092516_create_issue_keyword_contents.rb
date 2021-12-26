class CreateIssueKeywordContents < ActiveRecord::Migration[6.0]
  def change
    create_table :issue_keyword_contents do |t|
      t.references :issue_keyword, null: false, foreign_key: true
      t.string :url
      t.string :source

      t.timestamps
    end
  end
end
