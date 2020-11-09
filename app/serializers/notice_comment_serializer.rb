class NoticeCommentSerializer < ActiveModel::Serializer
  attribute :id
  attribute :notice_id
  attribute :user
  attributes NoticeComment.column_names.reject { |name| %w[id notice_id user_id password created_user_agent].include? name }
  attribute :replies

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
    addr = IPAddr.new(object.created_ip)

    if addr.ipv4?
      # set last octet to 0
      addr.to_s.gsub(/\.[0-9]{1,3}\.[0-9]{1,3}/, '')
    else
      # set last 80 bits to zeros
      addr.mask(20).to_s
    end
  end

  def replies
    ActiveModelSerializers::SerializableResource.new(
      object.notice_comment_replies.order(created_at: :asc),
      each_serializer: NoticeCommentReplySerializer
    )
  end
end
