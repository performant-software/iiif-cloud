class Public::ResourcesController < Api::ResourcesController
  # Includes
  include Public::Authenticateable

  # Actions
  prepend_before_action :set_project, only: [:create, :update]
  prepend_before_action :set_project_id, only: :index
  prepend_before_action :set_resource, only: [:show, :destroy, :update, :manifest]
  skip_before_action :authenticate_request, only: :manifest

  def manifest
    resource = Resource.find(params[:id])
    render json: JSON.parse(resource.manifest)
  end

  private

  def set_project
    project = Project.find_by_uuid(params[:resource][:project_id])
    render_unauthorized I18n.t('errors.unauthorized') and return if project.nil?

    params[:resource][:project_id] = project.id
  end

  def set_project_id
    project = Project.find_by_uuid(params[:project_id])
    render_unauthorized I18n.t('errors.unauthorized') and return if project.nil?

    params[:project_id] = project.id
  end

  def set_resource
    resource = Resource.find_by_uuid(params[:id])
    render_unauthorized I18n.t('errors.unauthorized') and return if resource.nil?

    params[:id] = resource.id
  end
end
