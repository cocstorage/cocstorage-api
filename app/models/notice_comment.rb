class NoticeComment < ApplicationRecord
  belongs_to :notice
  belongs_to :user, optional: true

  def self.create_with_options(options = {})
    options = options.merge(user_id: options[:user].id, is_member: true) if options[:user].present?
    options = options.merge(user_id: nil, is_member: false) if options[:user].blank?

    options = options.except(:user)

    create!(options)
  end
end
