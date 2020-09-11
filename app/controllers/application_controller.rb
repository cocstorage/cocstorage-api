class ApplicationController < ActionController::API
  rescue_from Errors::BadRequest, with: :bad_request
  rescue_from Errors::Unauthorized, with: :unauthorized
  rescue_from Errors::Forbidden, with: :forbidden
  rescue_from Errors::NotFound, with: :not_found

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
    head :forbidden
  end

  def not_found(error)
    render status: :not_found, json: {
      code: error.code,
      message: error.message
    }
  end

  def confirm_yourself
    if params[:id].to_i != current_v1_user.id
      raise Errors::BadRequest.new(code: 'COC012', message: 'Do not have permission to perform the request')
    end
  end
end
