class V1::UsersController < V1::BaseController
  skip_before_action :authenticate_v1_user!, only: %i[authentication]
  before_action :confirm_yourself, only: %i[update destroy privacy]

  def update
    render json: User.update_with_options(configure_update_params), each_serializer: UserSerializer
  end

  def destroy
    render json: User.withdrawal_reservation_with_options(configure_destroy_params), each_serializer: UserSerializer
  end

  def authentication
    ApplicationRecord.transaction do
      render json: User.authentication(params[:uuid]), each_serializer: UserSerializer
    end
  end

  def privacy
    user = User.find(current_v1_user.id)
    options = configure_privacy_params

    if BCrypt::Password.new(user.encrypted_password) != options[:password]
      raise Errors::BadRequest.new(code: 'COC027', message: 'Password do not match.')
    end

    render json: user.as_json(only: %w[name email]), each_serializer: UserSerializer
  end

  private

  def update_attributes
    %w[nickname current_password password avatar]
  end

  def destroy_attributes
    %w[password]
  end

  def privacy_attributes
    %w[password]
  end

  def configure_update_params
    if params.key? :nickname
      raise Errors::BadRequest.new(code: 'COC013', message: 'nickname is empty') if params[:nickname].blank?
    end

    if params.key? :password
      raise Errors::BadRequest.new(code: 'COC000', message: 'current_password is required') if params[:current_password].blank?
      raise Errors::BadRequest.new(code: 'COC013', message: 'password is empty') if params[:password].blank?
    end

    if params.key? :avatar
      unless params[:avatar].is_a? ActionDispatch::Http::UploadedFile
        raise Errors::BadRequest.new(code: 'COC014', message: 'avatar is not a file')
      end
    end

    params.permit(update_attributes).merge(user: current_v1_user)
  end

  def configure_destroy_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'password is required') if params[:password].blank?

    params.permit(destroy_attributes).merge(user: current_v1_user)
  end

  def configure_privacy_params
    raise Errors::BadRequest.new(code: 'COC000', message: 'password is required') if params[:password].blank?

    params.permit(privacy_attributes)
  end
end
