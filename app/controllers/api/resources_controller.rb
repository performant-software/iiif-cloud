class Api::ResourcesController < Api::BaseController
  # Includes
  include Api::Uploadable

  # Search attributes
  search_attributes :name

  # Preloads
  preloads Resource.attachment_preloads

  # Actions
  before_action :validate_new_resource, unless: -> { current_user.admin? }, only: :create
  before_action :validate_resource, unless: -> { current_user.admin? }, only: [:update, :destroy]

  def base_query
    subquery = Project.where(Project.arel_table[:id].eq(Resource.arel_table[:project_id]))

    if !current_user.admin?
      subquery = subquery
                   .joins(organization: :user_organizations)
                   .where(user_organizations: { user_id: current_user.id })
    end

    subquery = subquery.where(id: params[:project_id]) if params[:project_id].present?

    Resource.where(subquery.arel.exists)
  end

  private

  def validate_new_resource
    project = Project.find(params[:resource][:project_id])
    check_authorization project.organization_id
  end

  def validate_resource
    resource = Resource.find(params[:id])
    check_authorization resource.project.organization_id
  end
end