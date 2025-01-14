class Public::ResourcesController < Api::ResourcesController
  # Includes
  include Public::Authenticateable

  # Actions
  prepend_before_action :set_page, only: [:iiif, :info]
  prepend_before_action :set_project_id, only: :index
  prepend_before_action :set_resource_id, only: [:show, :destroy, :update]
  prepend_before_action :set_resource_project_id, only: [:create, :update]
  skip_before_action :authenticate_request, only: [:content, :download, :iiif, :info, :inline, :manifest, :preview, :thumbnail]

  def content
    redirect_resource do |resource|
      resource.content_url
    end
  end

  def download
    redirect_resource do |resource|
      resource.content_download_url
    end
  end

  def iiif
    page_number = params[:page] || 1

    redirect_resource do |resource|
      resource.image? ? resource.content_converted_iiif_url(page_number) : resource.content_iiif_url(page_number)
    end
  end

  def info
    page_number = params[:page] || 1

    redirect_resource do |resource|
      resource.image? ? resource.content_converted_info_url(page_number) : resource.content_info_url(page_number)
    end
  end

  def inline
    redirect_resource do |resource|
      resource.content_inline_url
    end
  end

  def manifest
    resource = Resource.find_by_uuid(params[:id])
    render json: JSON.parse(resource.manifest)
  end

  def preview
    redirect_resource do |resource|
      resource.image? ? resource.content_converted_preview_url : resource.content_preview_url
    end
  end

  def thumbnail
    redirect_resource do |resource|
      resource.image? ? resource.content_converted_thumbnail_url : resource.content_thumbnail_url
    end
  end

  private

  def redirect_resource
    resource = Resource.find_by_uuid(params[:id])
    render status: :not_found and return if resource.nil?
    
    redirect  = yield resource
    render status: :not_found and return if redirect.nil?

    redirect_to redirect, allow_other_host: true
  end

  def set_page
    id, page = params[:id].split(';')

    params[:id] = id
    params[:page] = page
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
