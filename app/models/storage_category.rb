class StorageCategory < ApplicationRecord
  has_many :storages

  def self.fetch_with_options(options = {})
    storageCategories = all

    storageCategories = storageCategories.where.not(name: '이슈') unless options[:withIssueCategory].present?

    storageCategories
  end
end
