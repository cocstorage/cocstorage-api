class StorageSerializer < ActiveModel::Serializer
  attributes Storage.column_names.reject { |name| %w[created_ip created_user_agent].include? name }
  attribute :avatar_url

  def avatar_url
    object.avatar_url
  end
end
