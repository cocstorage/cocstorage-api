class UserAuthenticateMailerJob < ApplicationJob
  queue_as :user_authenticate_mailers

  def perform(user)
    UserMailer.authenticate_email(user).deliver_now
  end
end
