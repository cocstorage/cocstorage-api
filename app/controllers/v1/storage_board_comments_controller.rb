class V1::StorageBoardCommentsController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[index non_members_create non_members_destroy]

  def index
    storage_board_comments = StorageBoardComment.fetch_with_options(configure_index_params)
    storage_board_comments = storage_board_comments.page(params[:page]).per(params[:per] || 20)

    render json: {
      comments: ActiveModelSerializers::SerializableResource.new(storage_board_comments, each_serializer: StorageBoardCommentSerializer),
      pagination: PaginationSerializer.new(storage_board_comments)
    }
  end

  def create
    render json: StorageBoardComment.create_with_options(configure_create_params)
  end

  def non_members_create
    render json: StorageBoardComment.create_with_options(configure_non_member_create_params), each_serializer: StorageBoardCommentSerializer
  end

  def destroy
    render json: StorageBoardComment.destroy_for_member(configure_destroy_params), each_serializer: StorageBoardCommentSerializer
  end

  def non_members_destroy
    render json: StorageBoardComment.destroy_for_non_member(configure_non_member_destroy_params), each_serializer: StorageBoardCommentSerializer
  end

  private

  def index_attributes
    %w[storage_id storage_board_id page per orderBy]
  end

  def create_attributes
    %w[storage_id storage_board_id content]
  end

  def non_member_create_attributes
    %w[storage_id storage_board_id nickname password content]
  end

  def destroy_attributes
    %w[storage_id storage_board_id id]
  end

  def non_member_destroy_attributes
    %w[storage_id storage_board_id id password]
  end

  def configure_index_params
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

  def configure_non_member_create_params
    non_member_create_attributes.each do |key|
      raise Errors::BadRequest.new(code: 'COC000', message: "#{key} is required") if params[key].blank?
    end

    params.permit(non_member_create_attributes).merge(
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )
  end

  def configure_destroy_params
    params.permit(destroy_attributes).merge(user: current_v1_user)
  end

  def configure_non_member_destroy_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'password is required') if params[:password].blank?

    params.permit(non_member_destroy_attributes)
  end
end
