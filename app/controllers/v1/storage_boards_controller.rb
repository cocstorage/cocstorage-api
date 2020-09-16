class V1::StorageBoardsController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: :index

  def drafts
    storage_board_draft = StorageBoard.create!(
      storage_id: params[:storage_id],
      user_id: current_v1_user.id,
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )

    render json: storage_board_draft
  end
end
