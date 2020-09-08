class V1::Users::SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    super
  end

  # DELETE /resource/sign_out
  def destroy
    super
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  end

  def respond_with(resource, _opts = {})
    unless resource.is_authenticated
      raise Errors::BadRequest.new(code: 'COC009', message: 'This account has not been authenticated by email')
    end
    unless resource.is_active
      raise Errors::BadRequest.new(code: 'COC010', message: 'This account has been deactivated')
    end
    if resource.withdrawaled_at.present?
      raise Errors::BadRequest.new(code: 'COC011', message: 'This account is in the process of withdrawal from membership')
    end

    render json: resource
  end

  def respond_to_on_destroy
    head :ok
  end
end
