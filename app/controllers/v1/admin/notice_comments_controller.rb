class V1::Admin::NoticeCommentsController < V1::Admin::BaseController
  skip_before_action :authenticate_v1_admin!, only: %i[create non_members_create]
  before_action :authenticate_v1_user!, only: %i[create]

  def index
    render json: {
      data: 'INDEX'
    }
  end

  def create
    render json: NoticeComment.create_with_options(configure_create_params), each_serializer: NoticeCommentSerializer
  end

  def non_members_create
    render json: NoticeComment.create_with_options(configure_non_members_create_params), each_serializer: NoticeCommentSerializer
  end

  private

  def create_attributes
    %w[notice_id content]
  end

  def non_members_create_attributes
    %w[notice_id nickname password content]
  end

  def configure_create_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'content is required') if params[:content].blank?

    params.permit(create_attributes).merge(
      user: current_v1_user,
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )
  end

  def configure_non_members_create_params
    non_members_create_attributes.each do |key|
      raise Errors::BadRequest.new(code: 'COC000', message: "#{key} is required") if params[key].blank?
    end

    params.permit(create_attributes).merge(
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )
  end
end
