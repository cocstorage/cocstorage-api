class V1::Admin::NoticesController < V1::Admin::BaseController
  skip_before_action :authenticate_v1_admin!, only: %i[index]

  def index
    notices = Notice.fetch_with_options(configure_index_params)
    notices = notices.page(params[:page]).per(params[:per] || 20)

    render json: {
      notices: notices,
      pagination: PaginationSerializer.new(notices)
    }
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
  private

  def index_attributes
    %w[orderBy per page]
  end

  def update_attributes
    %w[id subject content]
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
end
