class V1::StorageBoardCommentReplysController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[non_members_create]

  def create
    render json: StorageBoardCommentReply.create_with_options(create_params), each_serializer: StorageBoardCommentReplySerializer
  end

  def non_members_create
    render json: StorageBoardCommentReply.create_with_options(non_members_create_params), each_serializer: StorageBoardCommentReplySerializer
  end

  private

  def create_attributes
    %w[storage_board_comment_id content]
  end

  def non_members_create_attributes
    %w[storage_board_comment_id nickname password content]
  end

  def create_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'content is required') if params[:content].blank?

    params.permit(create_attributes).merge(
      user: current_v1_user,
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )
  end

  def non_members_create_params
    non_members_create_attributes.each do |key|
      raise Errors::BadRequest.new(code: 'COC000', message: "#{key} is required") if params[key].blank?
    end

    params.permit(non_members_create_attributes).merge(
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )
  end
end
