class V1::StorageBoardsController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[index show non_members_edit non_members_update non_members_destroy non_members_drafts view_count non_members_images non_members_recommend]

  def index
    storage_boards = StorageBoard.fetch_with_options(configure_index_params)
    storage_boards = storage_boards.page(params[:page]).per(params[:per] || 20)

    render json: {
      boards: ActiveModelSerializers::SerializableResource.new(storage_boards, each_serializer: StorageBoardSerializer),
      pagination: PaginationSerializer.new(storage_boards)
    }
  end

  def show
    render json: StorageBoard.find_activation_with_options(configure_show_params),
           each_serializer: StorageBoardSerializer
  end

  def edit
    render json: StorageBoard.find_with_options(configure_edit_params),
           each_serializer: StorageBoardSerializer
  end

  def non_members_edit
    render json: StorageBoard.find_for_non_member(configure_non_members_edit_params),
           each_serializer: StorageBoardSerializer
  end

  def update
    render json: StorageBoard.update_for_member(configure_update_params),
           each_serializer: StorageBoardSerializer
  end

  def non_members_update
    render json: StorageBoard.update_for_non_member(configure_non_members_update_params),
           each_serializer: StorageBoardSerializer
  end

  def destroy
    render json: StorageBoard.destroy_for_member(configure_destroy_params),
           each_serializer: StorageBoardSerializer
  end

  def non_members_destroy
    render json: StorageBoard.destroy_for_non_member(configure_non_members_destroy_params),
           each_serializer: StorageBoardSerializer
  end

  def drafts
    render json: StorageBoard.create_draft(configure_draft_params),
           each_serializer: StorageBoardSerializer
  end

  def non_members_drafts
    render json: StorageBoard.create_draft(configure_draft_params),
           each_serializer: StorageBoardSerializer
  end

  def view_count
    render json: StorageBoard.update_activation_view_count(params),
           each_serializer: StorageBoardSerializer
  end

  def images
    storage = StorageBoard.find_with_options(configure_images_params)
    storage.images.attach(params[:image])

    render json: {
      image_url: storage.last_image_url
    }
  end

  def non_members_images
    storage = StorageBoard.find_with_options(configure_images_params)
    storage.images.attach(params[:image])

    render json: {
      image_url: storage.last_image_url
    }
  end

  def recommend
    ApplicationRecord.transaction do
      render json: StorageBoard.update_recommend_for_member(configure_recommend_params),
             each_serializer: StorageBoardSerializer
    end
  end

  def non_members_recommend
    ApplicationRecord.transaction do
      render json: StorageBoard.update_recommend_for_non_members(non_members_configure_recommend_params),
             each_serializer: StorageBoardSerializer
    end
  end

  private

  def index_attributes
    %w[storage_id subject content nickname orderBy per page]
  end

  def show_attributes
    %w[storage_id id]
  end

  def edit_attributes
    %w[storage_id id]
  end

  def non_members_edit_attributes
    %w[storage_id id password]
  end

  def update_attributes
    %w[storage_id id subject content]
  end

  def non_members_update_attributes
    %w[storage_id id subject content nickname password]
  end

  def destroy_attributes
    %w[storage_id id]
  end

  def non_members_destroy_attributes
    %w[storage_id id password]
  end

  def images_attributes
    %w[storage_id id]
  end

  def recommend_attributes
    %w[storage_id id type]
  end

  def non_members_recommend_attributes
    %w[storage_id id type]
  end

  def configure_index_params
    params.permit(index_attributes)
  end

  def configure_show_params
    params.permit(show_attributes)
  end

  def configure_edit_params
    params.permit(edit_attributes).merge(user: current_v1_user)
  end

  def configure_non_members_edit_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'password is required') if params[:password].blank?

    params.permit(non_members_edit_attributes)
  end

  def configure_update_params
    params.permit(update_attributes).merge(user: current_v1_user)
  end

  def configure_non_members_update_params
    non_members_update_attributes.each do |key|
      if key == 'nickname'
        raise Errors::BadRequest.new(code: 'COC000', message: "#{key} is required") if params[key].blank?
      end

      if key == 'password'
        raise Errors::BadRequest.new(code: 'COC000', message: "#{key} is required") if params[key].blank?
      end
    end

    params.permit(non_members_update_attributes)
  end

  def configure_destroy_params
    params.permit(destroy_attributes).merge(user: current_v1_user)
  end

  def configure_non_members_destroy_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'password is required') if params[:password].blank?

    params.permit(non_members_destroy_attributes)
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

  def configure_recommend_params
    params.permit(recommend_attributes).merge(user: current_v1_user, request: request)
  end

  def non_members_configure_recommend_params
    params.permit(non_members_recommend_attributes).merge(request: request)
  end
end
