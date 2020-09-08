class V1::Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    user = User.create_user(configure_create_params)
    UserAuthenticationMailerJob.perform_later(user)
    render json: user, serializer: UserSerializer
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  def create_attributes
    %w[name email password]
  end

  def configure_create_params
    create_attributes.each do |attribute|
      raise Errors::BadRequest.new(code: 'COC000', message: "#{attribute} is required") if params[attribute].blank?

      if attribute == 'name'
        raise Errors::BadRequest.new(code: 'COC001', message: "#{attribute} is invalid") if params[attribute].length > 4
      end

      if attribute == 'email'
        if User.find_by(email: params[attribute]).present?
          raise Errors::BadRequest.new(code: 'COC003', message: 'email already exists')
        end
      end
    end

    params.permit(create_attributes).merge(created_ip: request.remote_ip)
  end
end
