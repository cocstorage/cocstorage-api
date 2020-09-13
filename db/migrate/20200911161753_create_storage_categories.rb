class CreateStorageCategories < ActiveRecord::Migration[6.0]
  def change
    create_table :storage_categories do |t|
      t.string :name
      t.string :code

      t.timestamps
    end
  end
end
