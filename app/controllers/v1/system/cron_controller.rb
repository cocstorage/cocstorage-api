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

  def scrap
    StorageBoardScrapJob.perform_later
    render json: {
      status: :ok
    }
  end

  def migration
    MigrationLegacyBoardJob.perform_later
    render json: {
      status: :ok
    }
  end
end
