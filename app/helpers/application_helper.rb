module ApplicationHelper
  def authenticate_v1_admin!
    raise Errors::Unauthorized unless warden.authenticate?
    raise Errors::Forbidden if warden.authenticate['role'] != 'admin'
  end
end
