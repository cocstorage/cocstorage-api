Rails.application.config.to_prepare do
  Warden::Proxy.module_eval do
    def authenticate!(*args)
      user, opts = _perform_authentication(*args)

      throw(:warden, opts) unless user

      unless user.is_authenticated
        raise Errors::WardenUnauthorized.new(code: 'COC009', message: 'This account has not been authenticated by email.')
      end

      unless user.is_active
        raise Errors::WardenUnauthorized.new(code: 'COC010', message: 'This account has been deactivated.')
      end

      if user.withdrawaled_at.present?
        raise Errors::WardenUnauthorized.new(code: 'COC011', message: 'This account is in the process of withdrawal from membership.')
      end

      user
    end
  end
end
