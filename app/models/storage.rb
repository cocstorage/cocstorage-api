class Storage < ApplicationRecord
  belongs_to :storage_category
  belongs_to :user

  enum storage_type: %w[major minor issue]

  has_many :storage_boards, dependent: :destroy
  has_many :storage_user_roles, dependent: :destroy

  has_one_attached :avatar, dependent: :destroy

  validate :path_inspection, on: %i[create update]
  validate :name_inspection, on: %i[create update]
  validate :description_inspection, on: %i[create update]
  validate :avatar_inspection, on: %i[create update]

  def self.fetch_with_options(options = {})
    storages = all.where(is_active: true)
    storages = storages.where('name like ?', "#{options[:name]}%") if options[:name].present?
    storages = storages.where(storage_type: options[:type]) if options[:type].present?

    if options[:orderBy].present?
      storages = storages.order(created_at: :desc) if options[:orderBy] == 'latest'
      storages = storages.order(created_at: :asc) if options[:orderBy] == 'old'
    end

    storages
  end

  def self.fetch_by_cached_with_options(options = {})
    redis_key = "storages-#{options.values.to_s}"
    namespace = 'storages'

    storages = Rails.cache.read(redis_key, namespace: namespace)
    pagination = Rails.cache.read("#{redis_key}/pagination", namespace: namespace)

    if storages.blank? || pagination.blank?
      storages = all.where(is_active: true)

      storages = storages.where('name like ?', "#{options[:name]}%") if options[:name].present?

      # Orders
      if options[:orderBy].present?
        storages = storages.order(created_at: :desc) if options[:orderBy] == 'latest'
        storages = storages.order(created_at: :asc) if options[:orderBy] == 'old'
      end

      storages = storages.page(options[:page]).per(options[:per] || 20)

      Rails.cache.write(redis_key, ActiveModelSerializers::SerializableResource.new(
        storages,
        each_serializer: StorageSerializer
      ).as_json, namespace: namespace)
      Rails.cache.write("#{redis_key}/pagination", PaginationSerializer.new(storages).as_json, namespace: namespace)

      storages = Rails.cache.read(redis_key, namespace: namespace)
      pagination = Rails.cache.read("#{redis_key}/pagination", namespace: namespace)
    end

    {
      storages: storages,
      pagination: pagination
    }
  end

  def self.find_active(id)
    storage = find_by(id: id, is_active: true)
    storage = find_by(path: id, is_active: true) if storage.blank?
    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if storage.blank?

    storage
  end

  def self.find_active_by_cached(id)
    redis_key = "storages-#{id}"
    namespace = 'storages-detail'

    storage = Rails.cache.read(redis_key, namespace: namespace)

    if storage.blank?
      storage = find_by(id: id, is_active: true)
      storage = find_by(path: id, is_active: true) if storage.blank?
      raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if storage.blank?

      Rails.cache.write(redis_key, StorageSerializer.new(storage).as_json, namespace: namespace)
      storage = Rails.cache.read(redis_key, namespace: namespace)
    end

    storage
  end

  def active_boards
    storage_boards.where(is_draft: false, is_active: true)
  end

  def avatar_url
    file_url_of(avatar)
  end

  protected

  def path_inspection
    if path.present?
      normal_regex = /[a-zA-Z0-9가-힣]{2,20}/
      special_regex = "[ !@\#$%^&*(),.?\":{}|<>]"

      raise Errors::BadRequest.new(code: 'COC001', message: 'storage path is invalid') unless path =~ normal_regex
      raise Errors::BadRequest.new(code: 'COC001', message: 'storage path is invalid') if path.length > 20
      raise Errors::BadRequest.new(code: 'COC001', message: 'storage path is invalid') if path.match(special_regex)

      storage = Storage.find_by(path: path)
      if storage.present? && id != storage.id
        raise Errors::BadRequest.new(code: 'COC024', message: 'storage path already exists')
      end
    end
  end

  def name_inspection
    if name.present?
      normal_regex = /[ㄱ-ㅎㅏ-ㅣ가-힣a-zA-Z0-9\-]{2,10}/
      only_number_regex = /^[0-9]*$/
      special_regex = "[!@\#$%^&*(),.?\":{}|<>]"

      raise Errors::BadRequest.new(code: 'COC001', message: 'storage name is invalid') unless name =~ normal_regex
      raise Errors::BadRequest.new(code: 'COC001', message: 'storage name is invalid') if name =~ only_number_regex
      raise Errors::BadRequest.new(code: 'COC001', message: 'storage name is invalid') if name.length > 20
      raise Errors::BadRequest.new(code: 'COC001', message: 'storage name is invalid') if name.match(special_regex)

      storage = Storage.find_by(name: name)
      if storage.present? && id != storage.id
        raise Errors::BadRequest.new(code: 'COC025', message: 'storage name already exists')
      end
    end
  end

  def description_inspection
    if description.present?
      raise Errors::BadRequest.new(code: 'COC002', message: 'description is invalid') if description.length > 200
    end
  end

  def avatar_inspection
    if avatar.attached? && !avatar.content_type.in?(%w[image/png image/gif image/jpg image/jpeg])
      Errors::BadRequest.new(code: 'COC016', message: "#{avatar.content_type} is unacceptable image format")
    end
  end
end
