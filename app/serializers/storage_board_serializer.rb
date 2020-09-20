class StorageBoardSerializer < ActiveModel::Serializer
  attribute :id
  attribute :storage
  attribute :user
  attributes StorageBoard.column_names.reject { |name| %w[id storage_id user_id password created_user_agent].include? name }
  attribute :thumbnail_url

  def storage
    storage = object.storage

    {
      id: storage.id,
      storage_category_id: storage.storage_category_id,
      path: storage.path,
      name: storage.name
    }
  end

  def user
    user = object.user

    if user.present?
      {
        id: user.id,
        nickname: user.nickname,
        role: user.role
      }
    end
  end

  def thumbnail_url
    object.thumbnail_url
  end

  def created_ip
    object.created_ip.gsub(/\.[0-9]{1,3}\.[0-9]{1,3}/, '')
  end
end
