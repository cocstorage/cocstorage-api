class UserAuthenticationMailerJob < ApplicationJob
  queue_as :user_authentication_mailers

  def perform(user)
    UserMailer.authentication_email(user).deliver_now
  end
end
