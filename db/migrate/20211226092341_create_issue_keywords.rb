class CreateIssueKeywords < ActiveRecord::Migration[6.0]
  def change
    create_table :issue_keywords do |t|
      t.string :keyword
      t.string :source
      t.string :original
      t.integer :count

      t.timestamps
    end
  end
end
