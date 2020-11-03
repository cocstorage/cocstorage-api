class V1::System::CronController < ApplicationController
  def user_withdrawaled
    UserWithdrawaledJob.perform_later
    render json: {
      status: :ok,
      message: 'Succeeded'
    }
  end
end
