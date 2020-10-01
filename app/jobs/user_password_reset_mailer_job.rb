class UserPasswordResetMailerJob < ApplicationJob
  queue_as :user_password_reset_mailers

  def perform(user, raw)
    UserMailer.reset_password_instructions(user, raw).deliver_now
  end
end
