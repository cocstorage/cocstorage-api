class StorageBoardCommentSerializer < ActiveModel::Serializer
  attribute :id
  attribute :storage_board_id
  attribute :user
  attributes StorageBoardComment.column_names.reject { |name| %w[id user_id storage_board_id password created_user_agent].include? name }

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

  def created_ip
    object.created_ip.gsub(/\.[0-9]{1,3}\.[0-9]{1,3}/, '')
  end
end