class V1::System::CronController < ApplicationController
  def withdrawaled
    UserWithdrawaledJob.perform_later
    render json: {
      status: :ok,
      message: 'Succeeded'
    }
  end

  def collection
    PopularStorageBoardCollectionJob.perform_later
    render json: {
      status: :ok,
      message: 'Succeeded'
    }
  end
end
