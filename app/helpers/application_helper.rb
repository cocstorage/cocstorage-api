module ApplicationHelper
  def authenticate_v1_admin!
    raise Errors::BadRequest.new(code: 'COC012', message: 'You need to sign in or sign up before continuing.') unless warden.authenticate?
    raise Errors::Forbidden.new(code: 'COC021', message: 'Do not have permission to perform the request') if warden.authenticate['role'] != 'admin'
  end
end
