class NoticeSerializer < ActiveModel::Serializer
  attribute :id
  attribute :user
  attributes Notice.column_names.reject { |name| %w[id user_id created_ip created_user_agent].include? name }
  attribute :thumbnail_url
  attribute :comment_total_count

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

  def comment_total_count
    object.comment_count + object.reply_count
  end
end
