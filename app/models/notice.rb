class Notice < ApplicationRecord
  belongs_to :user

  has_many :notice_comments, dependent: :destroy
  has_many_attached :images

  has_one_attached :thumbnail

  def self.fetch_with_options(options = {})
    notices = all

    if options[:orderBy].present?
      notices = notices.order(created_at: :desc) if options[:orderBy] == 'latest'
      notices = notices.order(created_at: :asc) if options[:orderBy] == 'old'
    end

    notices
  end

  def self.fetch_active_with_options(options = {})
    notices = all.where(is_draft: false, is_active: true)

    if options[:orderBy].present?
      notices = notices.order(created_at: :desc) if options[:orderBy] == 'latest'
      notices = notices.order(created_at: :asc) if options[:orderBy] == 'old'
    end

    notices
  end

  def self.fetch_active_by_cached_with_options(options = {})
    redis_key = "notices-#{options.values.to_s}"
    namespace = 'notices'

    notices = Rails.cache.read(redis_key, namespace: namespace)
    pagination = Rails.cache.read("#{redis_key}/pagination", namespace: namespace)

    if notices.blank? || pagination.blank?
      notices = all.where(is_draft: false, is_active: true)

      if options[:orderBy].present?
        notices = notices.order(created_at: :desc) if options[:orderBy] == 'latest'
        notices = notices.order(created_at: :asc) if options[:orderBy] == 'old'
      end

      notices = notices.page(options[:page]).per(options[:per] || 20)

      Rails.cache.write(redis_key, ActiveModelSerializers::SerializableResource.new(notices, each_serializer: NoticeSerializer).as_json, expires_in: 5.minutes, namespace: namespace)
      Rails.cache.write("#{redis_key}/pagination", PaginationSerializer.new(notices).as_json, expires_in: 5.minutes, namespace: namespace)

      notices = Rails.cache.read(redis_key, namespace: namespace)
      pagination = Rails.cache.read("#{redis_key}/pagination", namespace: namespace)
    end

    {
      notices: notices,
      pagination: pagination
    }
  end

  def self.find_with_options(options = {})
    options = options.merge(is_active: true)

    notice = find_by(options)
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if notice.blank?

    notice
  end

  def self.find_active_with_options(options = {})
    options = options.merge(is_draft: false, is_active: true)

    notice = find_by(options)
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if notice.blank?

    notice
  end

  def self.find_active_by_cached(options = {})
    redis_key = "notices-#{options[:id]}"
    namespace = 'notices-detail'

    notice = Rails.cache.read(redis_key, namespace: namespace)

    if notice.blank?
      notice = find_by(options)
      raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if notice.blank?

      Rails.cache.write(redis_key, NoticeSerializer.new(notice).as_json, namespace: namespace)
      notice = Rails.cache.read(redis_key, namespace: namespace)
    end

    notice
  end

  def self.update_with_options(options = {})
    notice = find_by(options.except(:subject, :content, :content_json, :description))
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if notice.blank?

    if options[:content_json].present?
      content_json = JSON.parse options[:content_json]

      content_json.each do |content|
        options = options.merge(has_image: true) if content["tag"] === "img"
      end

      options[:content_json] = content_json
    end

    options = options.except(:user)
    options = options.merge(is_draft: false)

    notice.update(options).inspect
    notice.attach_thumbnail
    notice
  end

  def self.update_active_view_count(options = {})
    notice = find_active_with_options(options)

    notice.increment!(:view_count, 1)
  end

  def attach_thumbnail
    thumbnail.attach(images.first.blob) if images.attached? && images.last.content_type != "video/mp4"
  end

  def active_comments
    notice_comments.where(is_active: true)
  end

  def thumbnail_url
    file_url_of(thumbnail)
  end

  def last_image_url
    last_files_url_of(images)
  end

  def comment_count
    notice_comments.size
  end

  def reply_count
    NoticeCommentReply.where(notice_comment_id: notice_comments.map(&:id)).size
  end
end
