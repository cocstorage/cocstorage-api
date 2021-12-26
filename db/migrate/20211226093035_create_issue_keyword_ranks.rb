class CreateIssueKeywordRanks < ActiveRecord::Migration[6.0]
  def change
    create_table :issue_keyword_ranks do |t|
      t.datetime :date
      t.json :ranks

      t.timestamps
    end
  end
end
