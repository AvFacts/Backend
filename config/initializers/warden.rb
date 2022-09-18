module UserRepository
  def self.find_for_jwt_authentication(sub)
    User.find_by!(username: sub)
  end
end

module RevocationStrategy
  def self.jwt_revoked?(payload, _user)
    JWTDenylist.exists?(jti: payload['jti'])
  end

  def self.revoke_jwt(payload, _user)
    JWTDenylist.find_or_create_by!(jti: payload['jti'])
  end
end

Warden::JWTAuth.configure do |config|
  config.secret   = Rails.application.credentials.warden_jwt_key
  config.mappings = {user: UserRepository}

  config.dispatch_requests = [
      ['POST', /^\/session/]
  ]
  config.revocation_requests = [
      ['DELETE', /^\/session/]
  ]

  config.revocation_strategies = {user: RevocationStrategy}
end

Warden::Strategies.add(:password) do
  def valid?
    params['username'] || params['password']
  end

  def authenticate!
    user = User.find_by(username: params['username'])&.authenticate(params['password'])
    (user == false) ? pass : success!(user)
  end
end

Rails.application.config.middleware.use Warden::Manager do |config|
  config.failure_app = ->(_) do
    return [401, {}, ['Authorization Required']]
  end
  config.default_scope = :user

  config.scope_defaults :user, strategies: %i[password jwt]
end

Rails.application.config.middleware.use Warden::JWTAuth::Middleware
