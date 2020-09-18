class V1::StorageBoardsController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[index drafts_non_members]

  def index
    storage_boards = StorageBoard.fetch_with_options(configure_index_params)
    storage_boards = storage_boards.page(params[:page]).per(params[:per] || 20)

    render json: {
      boards: ActiveModelSerializers::SerializableResource.new(storage_boards, each_serializer: StorageBoardSerializer),
      pagination: PaginationSerializer.new(storage_boards)
    }
  end

  def drafts
    storage_board_draft = StorageBoard.create(
      storage_id: params[:storage_id],
      user_id: current_v1_user.id,
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )

    render json: storage_board_draft
  end

  def drafts_non_members
    storage_board_draft = StorageBoard.create!(
      storage_id: params[:storage_id],
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )

    render json: storage_board_draft
  end

  private

  def index_attributes
    %w[storage_id subject content nickname orderBy per page]
  end

  def configure_index_params
    params.permit(index_attributes)
  end
end
