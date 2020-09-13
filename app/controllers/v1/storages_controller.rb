class V1::StoragesController < V1::BaseController
  def create
    render json: Storage.create!(configure_create_params)
  end

  protected

  def create_attributes
    %w[path name description avatar]
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

    params.permit(create_attributes).merge(other_require_params)
  end
end
