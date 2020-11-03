class UserWithdrawaledJob < ApplicationJob
  queue_as :user_withdrawaled

  def perform(*args)
    users = User.where.not(withdrawaled_at: true)

    users.map do |user|
      d_day = (DateTime.parse(user.withdrawaled_at.to_s) - DateTime.current).to_i
      user.destroy if d_day <= 0
    end
  end
end
