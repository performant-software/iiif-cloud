class Api::UsersController < Api::BaseController
  # Search attributes
  search_attributes :name, :email

  # Preloads
  preloads User.attachment_preloads
  preloads user_organizations: :organization, only: :show

  # Actions
  before_action :validate_new_user, unless: -> { current_user.admin? }, only: :create
  before_action :validate_user, unless: -> { current_user.admin? }, only: [:update, :destroy]

  def me
    return unless current_user

    puts "Attempting to authenticate user #{current_user.id}"

    clerk_user = get_clerk_data(current_user.sso_id)

    update_user_from_sso(current_user, clerk_user)
    sync_organizations_from_sso(current_user)

    serializer = UsersSerializer.new

    render json: serializer.render_show(current_user), status: :ok
  end

  protected

  def base_query
    return super if current_user.admin?

    User.where(
      UserOrganization
        .where(UserOrganization.arel_table[:user_id].eq(User.arel_table[:id]))
        .where(organization_id: current_user.user_organizations.pluck(:id))
        .arel
        .exists
    )
  end

  private

  def update_user_from_sso(local_user, sso_user)
    local_user.assign_attributes(
      admin: sso_user.private_metadata['is_global_admin'] == true,
      avatar_url: sso_user.profile_image_url
    )

    current_user.save!
  end

  def sync_organizations_from_sso(user)
    memberships = get_clerk_organization_memberships(user.sso_id)
    clerk_organization_ids = memberships.map { |membership| membership.organization.id }

    local_organization_ids = Organization.where(sso_id: clerk_organization_ids).pluck(:id)
    current_organization_ids = user.user_organizations.pluck(:organization_id)

    (local_organization_ids - current_organization_ids).each do |organization_id|
      user.user_organizations.create!(organization_id: organization_id)
    end

    removed_organization_ids = current_organization_ids - local_organization_ids
    user.user_organizations.where(organization_id: removed_organization_ids).destroy_all if removed_organization_ids.any?
  end

  def validate_new_user
    organization_ids = params[:user][:user_organizations].map{ |uo| uo[:organization_id] }
    check_authorization organization_ids
  end

  def validate_user
    user = User.find(params[:id])
    organization_ids = user.user_organizations.pluck(:organization_id)
    check_authorization organization_ids
  end
end
