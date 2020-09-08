class DeviseCustomFailure < Devise::FailureApp
  def respond
    if request.format == :json
      custom_error_response
    else
      super
    end
  end

  def custom_error_response
    self.status = 401
    self.content_type = 'application/json'
    self.response_body = {
      code: 'COC008',
      message: 'Invalid email or password'
    }.to_json
  end
end