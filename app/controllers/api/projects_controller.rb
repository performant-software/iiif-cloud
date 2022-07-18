class Api::ProjectsController < Api::BaseController
  # Search attributes
  search_attributes :name, :description, :uid

  # Preloads
  preloads Project.attachment_preloads, :organization

  # Actions
  before_action :validate_new_project, unless: -> { current_user.admin? }, only: :create
  before_action :validate_project, unless: -> { current_user.admin? }, only: [:update, :destroy]

  protected

  def base_query
    return super if current_user.admin?

    Project
      .where(
        UserOrganization
          .where(UserOrganization.arel_table[:organization_id].eq(Project.arel_table[:organization_id]))
          .where(user_id: current_user.id)
          .arel
          .exists
      )
  end

  private

  def validate_new_project
    organization_id = params[:project][:organization_id]
    check_authorization organization_id
  end

  def validate_project
    project = Project.find(params[:id])
    check_authorization project.organization_id
  end
end
