class StorageBoardSerializer < ActiveModel::Serializer
  attributes StorageBoard.column_names.reject { |name| %w[password created_user_agent].include? name }
  attribute :thumbnail_url
  attribute :created_ip

  def thumbnail_url
    object.thumbnail_url
  end

  def created_ip
    object.created_ip.gsub(/\.[0-9]{1,3}\.[0-9]{1,3}/, '')
  end
end
