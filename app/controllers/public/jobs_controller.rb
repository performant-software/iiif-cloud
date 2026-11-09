class Public::JobsController < ActionController::API
  # Includes
  include Public::Authenticateable

  # Actions
  before_action :authenticate_request

  # Reports the aggregate status of a Job (and, if it tracks a fanned-out batch of
  # CreateStaticAssetsJob runs, how many of those have completed/failed so far). Lets other
  # applications (e.g. core-data-cloud) poll for completion of work they enqueued here.
  def show
    job = Job.find_by(uuid: params[:id])
    render json: { errors: [I18n.t('errors.jobs_controller.not_found')] }, status: :not_found and return if job.nil?

    render json: {
      status: job.status,
      total_count: job.total_count,
      completed_count: job.completed_count,
      failed_count: job.failed_count
    }, status: :ok
  end
end
