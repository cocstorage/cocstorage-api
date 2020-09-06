class V1::UsersController < ApplicationController
  def authentication
    render json: User.authentication(params[:uuid]), serializer: UserSerializer
  end
end
