class StorageBoardCommentReplySerializer < ActiveModel::Serializer
  attribute :id
  attribute :storage_board_comment_id
  attribute :user
  attributes StorageBoardCommentReply.column_names.reject { |name| %w[id user_id password created_user_agent].include? name }

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
