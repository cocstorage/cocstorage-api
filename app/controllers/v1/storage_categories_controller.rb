class V1::StorageCategoriesController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[index]

  def index
    render json: {
      categories: StorageCategory.fetch_with_options(configure_index_params)
    }
  end

  private

  def index_attributes
    %w[withIssueCategory]
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
