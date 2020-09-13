class V1::UsersController < ApplicationController
  before_action :authenticate_v1_user!, only: %i[update destroy]
  before_action :confirm_yourself, only: %i[update destroy]

  def update
    user = User.find(current_v1_user.id)
    user.update(configure_update_params)

    render json: user, serializer: UserSerializer
  end

  def destroy
    render json: User.withdrawal_reservation(current_v1_user.id), serializer: UserSerializer
  end

  def authentication
    render json: User.authentication(params[:uuid]), serializer: UserSerializer
  end

  private

  def update_attributes
    %w[nickname password avatar]
  end

  def configure_update_params
    if params.key? :nickname
      raise Errors::BadRequest.new(code: 'COC013', message: 'nickname is empty') if params[:nickname].blank?
    end

    if params.key? :password
      raise Errors::BadRequest.new(code: 'COC013', message: 'password is empty') if params[:password].blank?
    end

    if params.key? :avatar
      unless params[:avatar].is_a? ActionDispatch::Http::UploadedFile
        raise Errors::BadRequest.new(code: 'COC014', message: 'avatar is not a file')
      end
    end

    params.permit(update_attributes)
  end
end