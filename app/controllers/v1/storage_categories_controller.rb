class V1::StorageCategoriesController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[index]

  def index
    render json: {
      categories: StorageCategory.all
    }
  end
end
