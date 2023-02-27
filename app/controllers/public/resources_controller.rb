class Public::ResourcesController < Api::ResourcesController
  # Actions
  prepend_before_action :set_project, only: [:create, :update]
  prepend_before_action :set_resource, only: [:show, :destroy, :update]

  protected

  def authenticate_request
    api_key = request.headers['X-API-KEY']
    render_unauthorized I18n.t('errors.unauthenticated') and return unless api_key.present?

    begin
      @current_user = User.find_by_api_key(api_key)
    rescue ActiveRecord::RecordNotFound => e
      render_unauthorized e.message
    end
  end

  private

  def render_unauthorized(errors)
    render json: { errors: errors }, status: :unauthorized
  end

  def set_project
    project = Project.find_by_uuid(params[:resource][:project_id])
    params[:resource][:project_id] = project.id
  end

  def set_resource
    resource = Resource.find_by_uuid(params[:id])
    params[:id] = resource.id
  end
end
