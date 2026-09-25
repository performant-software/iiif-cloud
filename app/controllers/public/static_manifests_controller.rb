class Public::StaticManifestsController < ActionController::API
  # Includes
  include Public::Authenticateable

  # Actions
  before_action :authenticate_request

  # Persists an already-built IIIF manifest/collection JSON document to storage, at an arbitrary
  # caller-provided path under destination. This deliberately has no knowledge of how the JSON
  # was built - it's a thin wrapper around the same Writer classes CreateStaticAssetsJob uses, so
  # other applications (e.g. core-data-cloud) can write static presentation documents without
  # needing their own storage credentials/writer code.
  def create
    render json: { errors: [I18n.t('errors.static_manifests_controller.create_invalid')] }, status: :unprocessable_entity and return unless validate_create?

    writer = Iiif::StaticAssets::Writers::R2Writer.new(params[:destination])
    writer.write(params[:path], JSON.pretty_generate(manifest_params))

    render json: {}, status: :ok
  rescue StandardError => e
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end

  private

  def validate_create?
    params[:destination].present? && params[:path].present? && params[:manifest].present?
  end

  def manifest_params
    params[:manifest].respond_to?(:to_unsafe_h) ? params[:manifest].to_unsafe_h : params[:manifest]
  end
end
