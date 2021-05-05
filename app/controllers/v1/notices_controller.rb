class V1::NoticesController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[index]

  def index
    data = Notice.fetch_active_by_cached_with_options(configure_index_params)

    render json: data
  end

  private

  def index_attributes
    %w[orderBy per page]
  end

  def configure_index_params
    index_attributes.each do |key|
      if params.key? key.to_sym
        raise Errors::BadRequest.new(code: 'COC013', message: "#{key} is empty") if params[key.to_sym].blank?
      end
    end

    params.permit(index_attributes)
  end
end
