class ApplicationController < ActionController::API
  rescue_from Errors::Unauthorized, with: :unauthorized
  rescue_from Errors::Forbidden, with: :forbidden
  rescue_from Errors::BadRequest, with: :bad_request

  def health_check
    head :ok
  end

  def unauthorized
    head :unauthorized
  end

  def forbidden(error)
    render status: :forbidden, json: {
      code: error.code,
      message: error.message
    }
  end

  def bad_request(error)
    render status: :bad_request, json: {
      code: error.code,
      message: error.message
    }
  end
end
