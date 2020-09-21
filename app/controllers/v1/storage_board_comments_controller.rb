class V1::StorageBoardCommentsController < V1::BaseController
  def create
    render json: StorageBoardComment.create_with_options(configure_create_params)
  end

  private

  def create_attributes
    %w[storage_id storage_board_id content]
  end

  def configure_create_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'content is required') if params[:content].blank?

    params.permit(create_attributes).merge(
      user: current_v1_user,
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )
  end
end
