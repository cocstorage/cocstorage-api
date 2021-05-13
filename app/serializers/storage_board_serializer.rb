class StorageBoardSerializer < ActiveModel::Serializer
  attribute :id
  attribute :storage
  attribute :user
  attributes StorageBoard.column_names.reject { |name| %w[id storage_id user_id password created_user_agent].include? name }
  attribute :thumbnail_url
  attribute :comment_total_count
  attribute :comment_latest_page

  def storage
    storage = object.storage

    {
      id: storage.id,
      storage_category_id: storage.storage_category_id,
      path: storage.path,
      name: storage.name,
      description: storage.description,
      avatar_url: storage.avatar_url
    }
  end

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

  def thumbnail_url
    object.thumbnail_url
  end

  def created_ip
    begin
      addr = IPAddr.new(object.created_ip)

      if addr.ipv4?
        # set last octet to 0
        addr.to_s.gsub(/\.[0-9]{1,3}\.[0-9]{1,3}/, '')
      else
        # set last 80 bits to zeros
        addr.mask(20).to_s
      end
    rescue
      object.created_ip
    end
  end

  def comment_total_count
    @comment_count = object.comment_count
    @reply_count = object.reply_count
    @comment_total_count = @comment_count + @reply_count

    @comment_total_count
  end

  def comment_latest_page
    @comment_count  % 10 != 0 ? ((@comment_count) / 10).ceil + 1 : ((@comment_count) / 10).ceil
  end
end
