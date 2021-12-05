class ApplicationController < ActionController::API
  before_action :validation_x_api_key
  skip_before_action :validation_x_api_key, only: [:health_check, :modules]

  rescue_from Errors::BadRequest, with: :bad_request
  rescue_from Errors::Unauthorized, with: :unauthorized
  rescue_from Errors::Forbidden, with: :forbidden
  rescue_from Errors::NotFound, with: :not_found
  rescue_from Errors::WardenUnauthorized, with: :warden_unauthorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  require 'modules/scraper'

  def modules
    # browser = Scraper.init_selenium_web_driver "chrome"

    dc = Scraper::Dcinside.new
    storage = Storage.find(2)
    test = dc.scrap_boards_by_storage storage
    render json: {
      data: test
    }
  end

  def health_check
    render json: {
      status: :ok,
      environment: Rails.env
    }
  end

  def bad_request(error)
    render status: :bad_request, json: {
      code: error.code,
      message: error.message
    }
  end

  def unauthorized
    render status: :unauthorized, json: {
      code: error.code,
      message: error.message
    }
  end

  def forbidden(error)
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

  def record_not_found
    render status: :not_found, json: {
      code: 'COC006',
      message: "There's no such resource."
    }
  end

  def record_invalid
    render status: :bad_request, json: {
      code: 'COC026',
      message: "There's invalid resource."
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
      raise Errors::Forbidden.new(code: 'COC021', message: 'Do not have permission to perform the request.')
    end
  end

  private

  def validation_x_api_key
    if request.headers['X-Api-Key'] != ENV['X_API_KEY']
      raise Errors::Forbidden.new(code: 'COC021', message: 'Do not have permission to perform the request.')
    end
  end

  def revoked_token
    token = request.env['warden-jwt_auth.token']

    if token.present?
      secret = ENV['DEVISE_JWT_SECRET_KEY']
      jti = JWT.decode(token, secret, true, algorithm: 'HS256', verify_jti: true)[0]['jti']
      exp = JWT.decode(token, secret, true, algorithm: 'HS256')[0]['exp']

      request.env['warden-jwt_auth.token'] = nil
      JwtDenylist.create(jti: jti, exp: Time.at(exp.to_i))
    end
  end
end
