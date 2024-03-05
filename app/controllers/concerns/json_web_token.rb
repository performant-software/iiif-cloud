class JsonWebToken
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, secret_key_base)
  end

  def self.decode(token)
    decoded = JWT.decode(token, secret_key_base)[0]
    HashWithIndifferentAccess.new decoded
  end

  private

  def self.secret_key_base
    return ENV['SECRET_KEY_BASE'] if ENV['SECRET_KEY_BASE'].present?

    Rails.application.secrets.secret_key_base.to_s
  end
end
