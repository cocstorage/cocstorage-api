class V1::StoragesController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[index show]

  def index
    data = Storage.fetch_by_cached_with_options(configure_index_params)

    render json: data
  end

  def show
    data = Storage.find_active_by_cached(params[:id])

    render json: data
  end

  def create
    ApplicationRecord.transaction do
      storage = Storage.create(configure_create_params)
      StorageUserRole.create(
        storage_id: storage.id,
        user_id: current_v1_user.id,
        role: 1,
        created_ip: request.headers['CF-Connecting-IP'] || request.remote_ip,
        created_user_agent: request.user_agent
      )

      Rails.cache.clear(namespace: 'storages')
      render json: storage, each_serializer: StorageSerializer
    end
  end

  private

  def index_attributes
    %w[name orderBy per page]
  end

  def create_attributes
    %w[path name description avatar]
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
    create_attributes.each do |key|
      if params[key].blank? && key != 'avatar'
        raise Errors::BadRequest.new(code: 'COC000', message: "#{key} is required")
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
      created_ip: request.headers['CF-Connecting-IP'] || request.remote_ip,
      created_user_agent: request.user_agent,
      code: params[:path]
    }

    params.permit(create_attributes).merge(other_require_params)
  end
end
