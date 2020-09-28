class NoticeCommentSerializer < ActiveModel::Serializer
  attribute :id
  attribute :notice_id
  attribute :user
  attributes NoticeComment.column_names.reject { |name| %w[id notice_id user_id password created_user_agent].include? name }

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

  def created_ip
    object.created_ip.gsub(/\.[0-9]{1,3}\.[0-9]{1,3}/, '')
  end
end
