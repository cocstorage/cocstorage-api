class StorageBoard < ApplicationRecord
  belongs_to :storage
  belongs_to :user, optional: true

  has_many_attached :images

  def self.fetch_with_options(options = {})
    storage_boards = where(storage_id: options[:storage_id])
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if storage_boards.blank?

    storage_boards = storage_boards.where(is_draft: false, is_active: true)
    storage_boards = storage_boards.where('subject like ?', "#{options[:subject]}%") if options[:subject].present?
    storage_boards = storage_boards.where('content like ?', "#{options[:content]}%") if options[:content].present?
    storage_boards = storage_boards.where('nickname like ?', "#{options[:nickname]}%") if options[:nickname].present?

    if options[:orderBy].present?
      storage_boards = storage_boards.order(created_at: :desc) if options[:orderBy] == 'latest'
      storage_boards = storage_boards.order(created_at: :asc) if options[:orderBy] == 'old'
    end

    storage_boards
  end

  def thumbnail_url
    file_url_of(images.first) if images.first.present?
  end
end
