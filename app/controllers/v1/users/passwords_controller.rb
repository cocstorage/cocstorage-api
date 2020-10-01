class V1::Users::PasswordsController < Devise::PasswordsController
  respond_to :json

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    user = resource_class.find_by(name: resource_params[:name], email: resource_params[:email])
    raise Errors::BadRequest.new(code: 'COC006', message: "There's no such resource.") if user.blank?

    user.send_reset_password_and_token

    respond_with(user)
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  protected

  def respond_with(resource, _opts = {})
    render json: resource
  end
end
