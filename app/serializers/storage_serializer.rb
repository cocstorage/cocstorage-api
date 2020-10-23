class StorageSerializer < ActiveModel::Serializer
  attribute :id
  attribute :storage_category_id
  attribute :user
  attributes Storage.column_names.reject { |name| %w[id storage_category_id user_id created_ip created_user_agent].include? name }
  attribute :avatar_url

  def user
    user = object.user

    if user.present?
      {
        id: user.id,
        nickname: user.nickname,
        role: user.role,
        avatar_url: user.avatar_url
      }
    end
  end

  def avatar_url
    object.avatar_url
  end
end
