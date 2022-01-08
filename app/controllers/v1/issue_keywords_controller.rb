class V1::IssueKeywordsController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[rank contents news]

  require 'open-uri'

  def rank
    render json: IssueKeywordRank.fetch_by_cached
  end

  def contents
    issue_keyword_contents = IssueKeywordContent.where(issue_keyword_id: configure_contents_params[:id])
    issue_keyword_contents = issue_keyword_contents.page(params[:page]).per(params[:per] || 20)

    render json: {
      contents: issue_keyword_contents,
      pagination: PaginationSerializer.new(issue_keyword_contents)
    }
  end

  def news
    response = URI.open("https://openapi.naver.com/v1/search/news.json?query=#{CGI.escape(params[:query])}&start=1&display=50",
                        'X-Naver-Client-Id' => ENV['X_NAVER_CLIENT_ID'],
                        'X-Naver-Client-Secret' => ENV['X_NAVER_CLIENT_SECRET']
    )

    raise Errors::NotFound.new(code: 'COC006', message: "There's no such resource.") if response.status.first.to_i >= 400

    news = JSON.parse(response.read)["items"]

    render json: {
      news: news
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
