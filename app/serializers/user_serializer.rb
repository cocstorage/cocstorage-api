class UserSerializer < ActiveModel::Serializer
  allow_column_names = %w[encrypted_password reset_password_token reset_password_sent_at remember_created_at created_ip]
  attributes User.column_names.reject { |name| allow_column_names.include? name }
  attribute :profile_image_url

  def profile_image_url
    object.profile_image_url
  end
end
