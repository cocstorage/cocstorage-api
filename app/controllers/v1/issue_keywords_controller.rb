class V1::IssueKeywordsController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[rank]

  def rank
    render json: IssueKeywordRank.last
  end
end
