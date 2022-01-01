class V1::IssueKeywordsController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[rank, contents]

  def rank
    render json: IssueKeywordRank.last
  end

  def contents
    issue_keyword_contents = IssueKeywordContent.where(issue_keyword_id: configure_contents_params[:id])
    issue_keyword_contents = issue_keyword_contents.page(params[:page]).per(params[:per] || 20)

    render json: {
      contents: issue_keyword_contents,
      pagination: PaginationSerializer.new(issue_keyword_contents)
    }
  end

  private

  def contents_attributes
    %w[id]
  end

  def configure_contents_params
    contents_attributes.each do |key|
      raise Errors::BadRequest.new(code: 'COC001', message: "#{key} is invalid") unless params[:id] =~ /^\d+$/
    end

    params.permit(contents_attributes)
  end
end
