class Api::ResourcesController < Api::BaseController
  # Includes
  include ActiveStorage::SetCurrent
  include Api::Uploadable
  include UserDefinedFields::Queryable

  # Search attributes
  search_attributes :name

  # Preloads
  preloads Resource.attachment_preloads

  # Actions
  before_action :set_defineable_params, only: :index
  before_action :validate_new_resource, unless: -> { current_user.admin? }, only: :create
  before_action :validate_resource, unless: -> { current_user.admin? }, only: [:update, :destroy]
  before_action :validate_resources, unless: -> { current_user.admin? }, only: :index

  def clear_cache
    render json: { errors: [I18n.t('errors.resources_controller.clear_cache')] }, status: :unauthorized and return unless can_clear_cache?

    resource = Resource.find(params[:id])
    key = resource.send(params[:attribute])&.key

    service = Cantaloupe::Api.new
    response = service.clear_cache(key)

    if response.success?
      render json: {}, status: :ok
    else
      error = response['exception'] || response['message'] || response['errors']
      render json: { errors: [error] }, status: :bad_request
    end
  end

  def convert
    render json: { errors: [I18n.t('errors.resources_controller.convert')] }, status: :unauthorized and return unless current_user.admin?

    resource = Resource.find(params[:id])
    ConvertImageJob.perform_later(resource.id)

    render json: {}, status: :ok
  end

  protected

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

  def can_clear_cache?
    # Only admin users can clear the cache
    return false unless current_user.admin?

    # Only clear the cache if the "attribute" param is present
    return false unless params[:attribute].present?

    # Only clear the cache if we have the necessary environment variables set
    vars = %w(CANTALOUPE_API_USERNAME CANTALOUPE_API_PASSWORD IIIF_HOST)
    return false unless vars.all? {|v| ENV[v].present? }

    true
  end

  def set_defineable_params
    return unless params[:project_id].present?

    params[:defineable_id] = params[:project_id]
    params[:defineable_type] = Project.to_s
  end

  def validate_new_resource
    project = Project.find(params[:resource][:project_id])
    check_authorization project.organization_id
  end

  def validate_resource
    resource = Resource.find(params[:id])
    check_authorization resource.project.organization_id
  end

  def validate_resources
    project = Project.find(params[:project_id])
    check_authorization project.organization_id
  end
end
