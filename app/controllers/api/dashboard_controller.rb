class Api::DashboardController < Api::BaseController
  def heap
    render json: { errors: [I18n.t('errors.dashboard_controller.unauthorized')] }, status: :unauthorized and return unless current_user.admin?

    service = Iiif::Server.new

    json = serializer.heap(
      service.status.dig(:data)
    )

    render json: json, status: :ok
  end

  def status
    render json: { errors: [I18n.t('errors.dashboard_controller.unauthorized')] }, status: :unauthorized and return unless current_user.admin?

    service = Iiif::Server.new

    json = serializer.status(
      service.health.dig(:data, :color),
      service.status.dig(:data)
    )

    render json: json, status: :ok
  end

  private

  def serializer
    DashboardSerializer.new
  end
end