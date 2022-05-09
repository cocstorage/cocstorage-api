class V1::System::CronController < ApplicationController
  def withdrawaled
    UserWithdrawaledJob.perform_later
    render json: {
      status: :ok,
      message: 'Succeeded'
    }
  end

  def collection
    PopularStorageBoardCollectionJob.perform_later if params[:type] == "popular"
    WorstStorageBoardCollectionJob.perform_later if params[:type] == "worst"

    render json: {
      status: :ok,
      message: 'Succeeded'
    }
  end

  def scrap
    StorageBoardScrapJob.perform_later
    render json: {
      status: :ok,
      message: 'Succeeded'
    }
  end

  def issue_keyword_scrap
    response = {
      status: :ok,
      message: 'Succeeded'
    }

    if params[:source] == "google"
      GoogleIssueKeywordScarpJob.perform_later
    elsif params[:source] == "zum"
      ZumIssueKeywordScarpJob.perform_later
    elsif params[:source] == "community"
      CommunityIssueKeywordScrapJob.perform_later
    else
      response = {
        status: :fail,
        message: "Invalid source"
      }
    end

    render json: response
  end

  def update_issue_keyword_rank
    IssueKeywordRankUpdateJob.perform_later
    render json: {
      status: :ok,
      message: 'Succeeded'
    }
  end
end
