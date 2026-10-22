class Public::ResourcesController < Api::ResourcesController
  # Includes
  include Public::Authenticateable

  # Actions
  prepend_before_action :set_page, only: [:iiif, :image_api, :info]
  prepend_before_action :set_project_id, only: :index
  prepend_before_action :set_resource_id, only: [:show, :destroy, :update]
  prepend_before_action :set_resource_project_id, only: [:create, :update]
  skip_before_action :authenticate_request, only: [:content, :download, :hls, :iiif, :image_api, :info, :inline, :manifest, :preview, :thumbnail]

  # Master playlist ("master.m3u8") or variant playlist ("stream_0/playlist.m3u8")
  HLS_PLAYLIST_PATH = %r{\A(stream_\d+/)?\w+\.m3u8\z}

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

  # Serves HLS playlists from the private bucket. Segment URIs are replaced with signed URLs, since players resolve
  # relative segment paths against the playlist URL and would drop the signature.
  def hls
    resource = Resource.find_by_uuid(params[:id])
    path = params[:path].to_s
    render status: :not_found and return unless resource&.hls? && path.match?(HLS_PLAYLIST_PATH)

    service = ActiveStorage::Blob.service
    prefix = ProcessVideoJob.hls_prefix(resource)
    playlist = service.download("#{prefix}/#{path}").force_encoding(Encoding::UTF_8)

    body = Videos::Playlist.rewrite(playlist, File.dirname(path)) do |segment_path|
      service.url(
        "#{prefix}/#{segment_path}",
        expires_in: Videos::Hls::SEGMENT_URL_EXPIRES_IN,
        filename: ActiveStorage::Filename.new(File.basename(segment_path)),
        disposition: :inline,
        content_type: Videos::Hls.content_type_for(segment_path)
      )
    end

    # Variant playlists contain expiring signed URLs
    response.headers['Cache-Control'] = 'no-store'
    render plain: body, content_type: Videos::Hls::CONTENT_TYPE_PLAYLIST
  rescue ActiveStorage::FileNotFoundError
    render status: :not_found
  end

  def iiif
    page_number = params[:page] || 1

    redirect_resource do |resource|
      if resource.converted_pages?
        resource.content_converted_pages_iiif_url(page_number.to_i)
      elsif resource.image?
        resource.content_converted_iiif_url(page_number)
      else
        resource.content_iiif_url(page_number)
      end
    end
  end

  def image_api
    page_number = params[:page] || 1

    redirect_resource do |resource|
      if resource.converted_pages?
        resource.content_converted_pages_image_api_url(
          page_number,
          params[:region],
          params[:size],
          params[:rotation],
          params[:quality],
          params[:format]
        )
      else
        resource.content_image_api_url(
          page_number,
          params[:region],
          params[:size],
          params[:rotation],
          params[:quality],
          params[:format]
        )
      end
    end
  end

  def info
    page_number = params[:page] || 1

    redirect_resource do |resource|
      if resource.converted_pages?
        resource.content_converted_pages_info_url(page_number)
      elsif resource.image?
        resource.content_converted_info_url(page_number)
      else
        resource.content_info_url(page_number)    
      end
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

  # No admin check here: storage credentials are always required below, and expected to be
  # narrowly scoped to the caller's own destination prefix, so a caller can't write anywhere it
  # doesn't already have a credential for. base_query (see Api::ResourcesController) further
  # restricts non-admins to resources belonging to their own organization, same as every other
  # action on this controller.
  def create_static_assets
    render json: { errors: [I18n.t('errors.resources_controller.create_static_assets_invalid')] }, status: :unprocessable_entity and return unless validate_static_assets?
    render json: { errors: [I18n.t('errors.resources_controller.create_static_assets_storage_invalid')] }, status: :unprocessable_entity and return unless validate_storage_params?

    resources = base_query.where(uuid: params[:resource_ids]).to_a
    render json: { errors: [I18n.t('errors.resources_controller.create_static_assets_resources_not_found')] }, status: :unprocessable_entity and return if resources.empty?

    job = find_or_create_job
    render json: { errors: [I18n.t('errors.resources_controller.create_static_assets_forbidden')] }, status: :forbidden and return if job.nil?

    JobItem.enqueue!(job: job, resource_ids: resources.map(&:id))
    store_storage_credentials(job)

    resources.each do |resource|
      CreateStaticAssetsJob.perform_later(resource.id, params[:base_url], params[:destination], job_uuid: job.uuid)
    end

    render json: { job_uuid: job.uuid }, status: :ok
  end

  def preview
    page_number = params[:page] || 1

    redirect_resource do |resource|
      if resource.converted_pages?
        resource.content_converted_pages_preview_url(page_number)
      elsif resource.image?
        resource.content_converted_preview_url
      else
        resource.content_preview_url
      end
    end
  end

  def thumbnail
    page_number = params[:page] || 1

    redirect_resource do |resource|
      if resource.converted_pages?
        resource.content_converted_pages_thumbnail_url(page_number)
      elsif resource.image?
        resource.content_converted_thumbnail_url
      else
        resource.content_thumbnail_url
      end
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

  def validate_static_assets?
    %i(resource_ids base_url destination).all? { |key| params[key].present? }
  end

  # An optional caller-supplied job_uuid lets multiple batches (e.g. core-data-cloud's chunked
  # calls for one logical export) accumulate under a single trackable Job; if omitted, a new one
  # is generated so standalone callers still get a job_uuid back to poll.
  #
  # job_uuid is caller-supplied and otherwise unconstrained - nothing stops two unrelated callers
  # from coincidentally (or deliberately) reusing the same value. Without an ownership check, that
  # could let one caller's request overwrite another's already-stored storage_credentials (see
  # #store_storage_credentials) or mix unrelated resources into the same Job's counts. Scoping to
  # user rather than organization because organization is shared across many users/API keys and
  # so wouldn't actually prevent that collision.
  #
  # Returns nil (rather than raising) when an existing job belongs to someone else, so the caller
  # can render a 403 without creating/touching anything. A job with no recorded owner (user_id
  # nil - every job created before this check existed) is treated the same as a mismatched owner:
  # it can never be "adopted" by whichever caller happens to reuse its uuid next, by anyone.
  def find_or_create_job
    existing = Job.find_by(uuid: params[:job_uuid]) if params[:job_uuid].present?
    return existing if existing && existing.user_id == current_user.id
    return nil if existing

    Job.create!(uuid: params[:job_uuid].presence || SecureRandom.uuid, status: Job::STATUS_PROCESSING, user: current_user)
  end

  # storage credentials are always required (bucket/access_key_id/secret_access_key); there is no
  # fallback to this process's own environment-configured credentials for this endpoint, since the
  # whole point is for each caller to supply its own narrowly-scoped, often short-lived credential
  # rather than share one long-lived, bucket-wide one. session_token is optional, since it's only
  # meaningful for temporary/STS-issued credentials.
  def validate_storage_params?
    return false unless params[:storage].present?

    %i(bucket access_key_id secret_access_key).all? { |key| params[:storage][key].present? }
  end

  # Persists the caller-supplied storage credentials on the Job row, keyed by job_uuid, so that
  # every CreateStaticAssetsJob run under this job_uuid can look them up without the credentials
  # being duplicated across each job's own Sidekiq arguments.
  def store_storage_credentials(job)
    credentials = params[:storage].slice(:bucket, :access_key_id, :secret_access_key, :session_token).to_unsafe_h
    job.update!(extra: job.extra.merge('storage_credentials' => credentials))
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
