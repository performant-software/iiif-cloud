require 'clerk'

class Api::BaseController < Api::ResourceController
  protected

  before_action :authenticate_request

  attr_reader :current_user

  def authenticate_request
    token = request.cookies["__session"]
    return deny_access unless token.present?

    clerk_session = clerk_client.verify_token(token)
    clerk_id = clerk_session["sub"]

    @current_user = User.find_by(sso_id: clerk_id)

    # If the user exists in Clerk but not in FairImage,
    # create a local account for them automatically.
    if @current_user.nil?
      clerk_user = get_clerk_data(clerk_id)
      @current_user = create_user_from_clerk(clerk_user)
    end

    return deny_access unless @current_user

    @current_user
  end

  def clerk_client
    @clerk_client ||= Clerk::SDK.new(secret_key: ENV.fetch("CLERK_SECRET_KEY"))
  end

  def create_user_from_clerk(clerk_user)
    user = User.new(
      sso_id: clerk_user.id,
      email: clerk_user.email_addresses.first.email_address,
      name: [clerk_user.first_name, clerk_user.last_name].join(" "),
      role: 'member',
    )

    user.save!

    user
  end

  def get_clerk_data(clerk_id)
    clerk_client.users.get(user_id: clerk_id).user
  end

  def get_clerk_organization_memberships(clerk_id)
    clerk_client.users.get_organization_memberships(user_id: clerk_id, limit: 500).organization_memberships.data
  end

  def get_clerk_role(clerk_user)
    clerk_user.public_metadata["role"]
  end

  def check_authorization(organization_id)
    deny_access unless current_user.has_access?(organization_id)
  end

  def deny_access
    render json: { errors: [I18n.t('errors.unauthorized')] }, status: :forbidden
  end
end
