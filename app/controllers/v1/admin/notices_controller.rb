class V1::Admin::NoticesController < V1::Admin::BaseController
  skip_before_action :authenticate_v1_admin!, only: %i[index show view_count]

  def index
    notices = Notice.fetch_with_options(configure_index_params)
    notices = notices.page(params[:page]).per(params[:per] || 20)

    render json: {
      notices: notices,
      pagination: PaginationSerializer.new(notices)
    }
  end

  def show
    render json: Notice.find(params[:id])
  end

  def edit
    render json: Notice.find(params[:id])
  end

  def update
    render json: Notice.update_with_options(configure_update_params)
  end

  def drafts
    render json: Notice.create!(
      user_id: current_v1_user.id,
      created_ip: request.remote_ip,
      created_user_agent: request.user_agent
    )
  end

  def images
    notice = Notice.find_with_options(configure_images_params)
    notice.images.attach(params[:image])

    render json: {
      image_url: notice.last_image_url
    }
  end

  def view_count
    render json: Notice.update_active_view_count(configure_view_count_params)
  end

  private

  def index_attributes
    %w[orderBy per page]
  end

  def update_attributes
    %w[id subject content]
  end

  def images_attributes
    %w[id]
  end

  def view_count_attributes
    %w[id]
  end

  def configure_index_params
    index_attributes.each do |key|
      if params.key? key.to_sym
        raise Errors::BadRequest.new(code: 'COC013', message: "#{key} is empty") if params[key.to_sym].blank?
      end
    end

    params.permit(index_attributes)
  end

  def configure_update_params
    if params.key? :subject
      raise Errors::BadRequest.new(code: 'COC013', message: 'subject is empty') if params[:subject].blank?
    end

    if params.key? :content
      raise Errors::BadRequest.new(code: 'COC013', message: 'content is empty') if params[:content].blank?
    end

    params.permit(update_attributes).merge(user: current_v1_user)
  end

  def configure_images_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'image is required') if params[:image].blank?

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

  def configure_view_count_params
    params.permit(view_count_attributes)
  end
end
