class V1::Admin::NoticeCommentsController < V1::Admin::BaseController
  skip_before_action :authenticate_v1_admin!, only: %i[index create non_members_create]
  before_action :authenticate_v1_user!, only: %i[create]

  def index
    notice_comments = NoticeComment.fetch_with_options(configure_index_params)
    notice_comments = notice_comments.page(params[:page]).per(params[:per] || 20)

    render json: {
      comments: ActiveModelSerializers::SerializableResource.new(
        notice_comments,
        each_serializer: NoticeCommentSerializer
      ),
      pagination: PaginationSerializer.new(notice_comments)
    }
  end

  def create
    render json: NoticeComment.create_with_options(configure_create_params), each_serializer: NoticeCommentSerializer
  end

  def non_members_create
    render json: NoticeComment.create_with_options(configure_non_members_create_params), each_serializer: NoticeCommentSerializer
  end

  private

  def index_attributes
    %w[notice_id page per orderBy]
  end

  def create_attributes
    %w[notice_id content]
  end

  def non_members_create_attributes
    %w[notice_id nickname password content]
  end

  def configure_index_params
    index_attributes.each do |key|
      if params.key? key.to_sym
        raise Errors::BadRequest.new(code: 'COC013', message: "#{key} is empty") if params[key.to_sym].blank?
      end
    end

    params.permit(index_attributes)
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

    params.permit(non_members_create_attributes).merge(
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )
  end
end
