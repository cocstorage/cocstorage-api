class V1::StorageBoardsController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[index show drafts_non_members view_count images_non_members]

  def index
    storage_boards = StorageBoard.fetch_with_options(configure_index_params)
    storage_boards = storage_boards.page(params[:page]).per(params[:per] || 20)

    render json: {
      boards: ActiveModelSerializers::SerializableResource.new(storage_boards, each_serializer: StorageBoardSerializer),
      pagination: PaginationSerializer.new(storage_boards)
    }
  end

  def show
    render json: StorageBoard.find_activation_with_options(configure_show_params), each_serializer: StorageBoardSerializer
  end

  def drafts
    render json: StorageBoard.create_draft_with_options(configure_draft_params)
  end

  def drafts_non_members
    render json: StorageBoard.create_draft_with_options(configure_draft_params)
  end

  def view_count
    render json: StorageBoard.update_activation_view_count_with_options(params), each_serializer: StorageBoardSerializer
  end

  def images
    storage = StorageBoard.find_by_with_options(configure_images_params)
    storage.images.attach(params[:image])

    render json: {
      image_url: storage.last_image_url
    }
  end

  def images_non_members
    storage = StorageBoard.find_by_with_options(configure_images_params)
    storage.images.attach(params[:image])

    render json: {
      image_url: storage.last_image_url
    }
  end

  private

  def index_attributes
    %w[storage_id subject content nickname orderBy per page]
  end

  def show_attributes
    %w[storage_id id]
  end

  def images_attributes
    %w[storage_id id]
  end

  def configure_index_params
    params.permit(index_attributes)
  end

  def configure_show_params
    params.permit(show_attributes)
  end

  def configure_draft_params
    {
      storage_id: params[:storage_id],
      user: current_v1_user,
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    }
  end

  def configure_images_params
    if params.key? :image
      unless params[:image].is_a? ActionDispatch::Http::UploadedFile
        raise Errors::BadRequest.new(code: 'COC014', message: 'image is not a file')
      end

      unless params[:image].content_type.in?(%w[image/png image/gif image/jpg image/jpeg])
        raise Errors::BadRequest.new(code: 'COC016', message: "#{params[:image].content_type} is unacceptable image format")
      end
    end

    params.permit(images_attributes).merge(user: current_v1_user)
  end
end
