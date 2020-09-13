class ApplicationController < ActionController::API
  rescue_from Errors::BadRequest, with: :bad_request
  rescue_from Errors::Unauthorized, with: :unauthorized
  rescue_from Errors::Forbidden, with: :forbidden
  rescue_from Errors::NotFound, with: :not_found
  rescue_from Errors::WardenUnauthorized, with: :warden_unauthorized

  def health_check
    head :ok
  end

  def bad_request(error)
    render status: :bad_request, json: {
      code: error.code,
      message: error.message
    }
  end

  def unauthorized
    head :unauthorized
  end

  def forbidden
    render status: :forbidden, json: {
      code: error.code,
      message: error.message
    }
  end

  def not_found(error)
    render status: :not_found, json: {
      code: error.code,
      message: error.message
    }
  end

  def warden_unauthorized(error)
    revoked_token
    render status: :unauthorized, json: {
      code: error.code,
      message: error.message
    }
  end

  def confirm_yourself
    if params[:id].to_i != current_v1_user.id
      raise Errors::BadRequest.new(code: 'COC021', message: 'Do not have permission to perform the request')
    end
  end

  private

  def revoked_token
    token = request.env['warden-jwt_auth.token']
    secret = ENV['DEVISE_JWT_SECRET_KEY']
    jti = JWT.decode(token, secret, true, algorithm: 'HS256', verify_jti: true)[0]['jti']
    exp = JWT.decode(token, secret, true, algorithm: 'HS256')[0]['exp']

    request.env['warden-jwt_auth.token'] = nil
    JwtDenylist.create(jti: jti, exp: Time.at(exp.to_i))
  end
end
