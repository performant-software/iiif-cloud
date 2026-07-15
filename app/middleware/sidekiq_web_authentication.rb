require 'clerk'

# Restricts the Sidekiq Web UI to admins authenticated via Clerk.
class SidekiqWebAuthentication
  def initialize(app)
    @app = app
  end

  def call(env)
    token = Rack::Request.new(env).cookies['__session']
    return deny_access unless token.present?

    clerk_id = begin
      clerk_client.verify_token(token)['sub']
    rescue JWT::DecodeError, Clerk::Error
      nil
    end
    return deny_access unless clerk_id

    user = User.find_by(sso_id: clerk_id)
    return deny_access unless user&.admin?

    @app.call(env)
  end

  private

  def clerk_client
    @clerk_client ||= Clerk::SDK.new(secret_key: ENV.fetch('CLERK_SECRET_KEY'))
  end

  def deny_access
    [403, { 'Content-Type' => 'text/plain' }, ['Forbidden']]
  end
end
