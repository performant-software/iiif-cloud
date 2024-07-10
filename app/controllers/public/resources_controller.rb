class Public::ResourcesController < Api::ResourcesController
  # Includes
  include Public::Authenticateable

  # Actions
  prepend_before_action :set_project_id, only: :index
  prepend_before_action :set_resource_id, only: [:show, :destroy, :update]
  prepend_before_action :set_resource_project_id, only: [:create, :update]
  skip_before_action :authenticate_request, only: [:content, :download, :iiif, :inline, :manifest, :preview, :thumbnail]

  def content
    redirect_resource :content_url
  end

  def download
    redirect_resource :content_download_url
  end

  def iiif
    redirect_resource :content_iiif_url
  end

  def inline
    redirect_resource :content_inline_url
  end

  def manifest
    resource = Resource.find_by_uuid(params[:id])
    render json: JSON.parse(resource.manifest)
  end

  def preview
    redirect_resource :content_preview_url
  end

  def thumbnail
    redirect_resource :content_thumbnail_url
  end

  private

  def redirect_resource(attribute)
    resource = Resource.find_by_uuid(params[:id])
    render status: :not_found and return if resource.nil?

    redirect  = resource.send(attribute)
    render status: :not_found and return if redirect.nil?

    redirect_to redirect, allow_other_host: true
  end

  def set_project_id
    project = Project.find_by_uuid(params[:project_id])
    render_unauthorized I18n.t('errors.unauthorized') and return if project.nil?

    params[:project_id] = project.id
  end

  def set_resource_id
    resource = Resource.find_by_uuid(params[:id])
    render_unauthorized I18n.t('errors.unauthorized') and return if resource.nil?

    params[:id] = resource.id
  end

  def set_resource_project_id
    project = Project.find_by_uuid(params[:resource][:project_id])
    render_unauthorized I18n.t('errors.unauthorized') and return if project.nil?

    params[:resource][:project_id] = project.id
  end
end
