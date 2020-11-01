class UserSerializer < ActiveModel::Serializer
  not_allow_column_names = %w[name email encrypted_password reset_password_token reset_password_sent_at point is_active remember_created_at created_ip created_user_agent created_at updated_at withdrawaled_at]
  attributes User.column_names.reject { |name| not_allow_column_names.include? name }
  attribute :avatar_url

  def avatar_url
    object.avatar_url
  end
end
