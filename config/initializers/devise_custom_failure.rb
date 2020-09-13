class DeviseCustomFailure < Devise::FailureApp
  def http_auth_body
    self.status = 401
    self.content_type = 'application/json'
    self.response_body = {
      code: get_error_code(i18n_message),
      message: i18n_message
    }.to_json
  end

  protected

  def get_error_code(message)
    codes = {
      "You need to sign in or sign up before continuing.": 'COC012',
      "Invalid Email or password.": 'COC008',
      "Signature has expired": 'COC022',
      "revoked token": 'COC023'
    }

    codes[message.to_sym]
  end
end