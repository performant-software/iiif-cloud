class Api::AuthenticationController < Api::BaseController
  # Actions
  skip_before_action :authenticate_request

  DEFAULT_EXPIRATION = '24'

  def login
    user = User.find_by_email(params[:email])

    if user&.authenticate(params[:password])
      render json: authentication_json(user), status: :ok
    else
      render json: { error: 'unauthorized' }, status: :unauthorized
    end
  end

  private

  def authentication_json(user)
    token = JsonWebToken.encode(user_id: user.id)
    time = Time.now + ENV.fetch('AUTHENTICATION_EXPIRATION') { DEFAULT_EXPIRATION }.to_i.hours.to_i

    serializer = UsersSerializer.new(current_user)

    {
      token: token,
      exp: time.strftime("%m-%d-%Y %H:%M"),
      username: user.email,
      user: serializer.render_show(user),
      admin: user.admin?,
      id: user.id
    }
  end
end
