class V1::StoragesController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: :index

  def index
    storages = Storage.fetch_with_options(configure_index_params)
    storages = storages.page(params[:page]).per(params[:per] || 20)

    render json: {
      storages: ActiveModelSerializers::SerializableResource.new(storages, each_serializer: StorageSerializer),
      pagination: PaginationSerializer.new(storages)
    }
  end

  def create
    storage = Storage.create!(configure_create_params)
    StorageUserRole.create(
      storage_id: storage.id,
      user_id: current_v1_user.id,
      role: 0,
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )

    render json: storage, each_serializer: StorageSerializer
  end

  private

  def index_attributes
    %w[name orderBy per page]
  end

  def create_attributes
    %w[path name description avatar]
  end

  def configure_index_params
    params.permit(index_attributes)
  end

  def configure_create_params
    create_attributes.each do |attribute|
      if params[attribute].blank? && attribute != 'avatar'
        raise Errors::BadRequest.new(code: 'COC000', message: "#{attribute} is required")
      end
    end

    if params[:avatar].present?
      unless params[:avatar].is_a? ActionDispatch::Http::UploadedFile
        raise Errors::BadRequest.new(code: 'COC014', message: 'avatar is not a file')
      end
    end

    other_require_params = {
      storage_category_id: 1,
      user_id: current_v1_user.id,
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    }

    puts other_require_params

    params.permit(create_attributes).merge(other_require_params)
  end
end
