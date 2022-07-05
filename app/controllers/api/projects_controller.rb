class Api::ProjectsController < Api::BaseController
  search_attributes :name, :description, :uid

  protected

  def base_query
    return super if current_user.admin?

    organization_ids = current_user.user_organizations.pluck(:organization_id)
    Project.where(organization_id: organization_ids)
  end
end
