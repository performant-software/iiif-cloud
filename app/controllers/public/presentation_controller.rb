module Public
  class PresentationController < ActionController::API
    # Includes
    include Public::Authenticateable

    def collection
      render json: { errors: [I18n.t('errors.presentation_controller.collection_invalid')] }, status: :unprocessable_entity and return unless validate_collection?

      json = Iiif::Collection.create(
        id: params[:id],
        label: params[:label],
        items: params[:items]
      )

      render json: json, status: :ok
    end

    def manifest
      render json: { errors: [I18n.t('errors.presentation_controller.manifest_invalid')] }, status: :unprocessable_entity and return unless validate_manifest?

      resources = Resource
                    .preload(Resource.attachment_preloads)
                    .where(uuid: params[:resource_ids])

      json = Iiif::Manifest.create(
        id: params[:id],
        label: params[:label],
        resources: resources
      )

      render json: json, status: :ok
    end

    private

    def validate_collection?
      validate_params? %i(id label items)
    end

    def validate_manifest?
      validate_params? %i(id label resource_ids)
    end

    def validate_params?(keys)
      keys.all? { |p| params[p].present? }
    end
  end
end