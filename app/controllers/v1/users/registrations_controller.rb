class V1::Users::RegistrationsController < Devise::RegistrationsController
  def create
    ApplicationRecord.transaction do
      user = User.create_with_options(configure_create_params)
      UserAuthenticationMailerJob.perform_later(user)

      render json: user, each_serializer: UserSerializer
    end
  end

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
    create_attributes.each do |key|
      raise Errors::BadRequest.new(code: 'COC000', message: "#{key} is required") if params[key].blank?
    end

    params.permit(create_attributes).merge(created_ip: request.remote_ip)
  end
end
