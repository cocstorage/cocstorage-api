class StorageSerializer < ActiveModel::Serializer
  attributes Storage.column_names
  attribute :avatar_url

  def avatar_url
    object.avatar_url
  end
end
