require 'test_helper'

class Public::ResourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: 'Test Organization')
    @other_organization = Organization.create!(name: 'Other Organization')

    @project = Project.create!(organization: @organization, name: 'Test Project')
    @other_project = Project.create!(organization: @other_organization, name: 'Other Project')

    @resource = Resource.create!(project: @project, name: 'Test Resource')
    @other_resource = Resource.create!(project: @other_project, name: 'Other Resource')

    @user = User.create!(name: 'API User', email: 'api-user@example.com', api_key: 'valid-api-key', admin: true)
    UserOrganization.create!(user: @user, organization: @organization)
  end

  test 'requires a valid API key' do
    post create_static_assets_public_resources_path, params: {
      resource_ids: [@resource.uuid],
      base_url: 'https://static.example/images',
      destination: 'static-assets'
    }, as: :json

    assert_response :unauthorized
  end

  test 'rejects an unrecognized API key' do
    post create_static_assets_public_resources_path,
      params: { resource_ids: [@resource.uuid], base_url: 'https://static.example/images', destination: 'static-assets' },
      headers: { 'X-API-KEY' => 'not-a-real-key' },
      as: :json

    assert_response :unauthorized
  end

  test 'requires resource_ids, base_url, and destination' do
    post create_static_assets_public_resources_path,
      params: { resource_ids: [@resource.uuid] },
      headers: { 'X-API-KEY' => @user.api_key },
      as: :json

    assert_response :unprocessable_entity
  end

  test 'queues static asset generation for accessible resources' do
    post create_static_assets_public_resources_path,
      params: {
        resource_ids: [@resource.uuid],
        base_url: 'https://static.example/images',
        destination: 'static-assets',
        storage: valid_storage_params
      },
      headers: { 'X-API-KEY' => @user.api_key },
      as: :json

    assert_response :ok

    job_uuid = JSON.parse(response.body)['job_uuid']
    assert_enqueued_with(job: CreateStaticAssetsJob, args: [@resource.id, 'https://static.example/images', 'static-assets', { job_uuid: job_uuid }])
  end

  test 'rejects a request whose resource_ids match no accessible resource' do
    assert_no_enqueued_jobs only: CreateStaticAssetsJob do
      post create_static_assets_public_resources_path,
        params: {
          resource_ids: [SecureRandom.uuid],
          base_url: 'https://static.example/images',
          destination: 'static-assets',
          storage: valid_storage_params
        },
        headers: { 'X-API-KEY' => @user.api_key },
        as: :json
    end

    assert_response :unprocessable_entity
    # No Job should be created (and no storage credentials stored) for a request that never
    # ends up doing anything.
    assert_equal 0, Job.count
  end

  test 'admins are not restricted to their own organizations\' resources' do
    post create_static_assets_public_resources_path,
      params: {
        resource_ids: [@other_resource.uuid],
        base_url: 'https://static.example/images',
        destination: 'static-assets',
        storage: valid_storage_params
      },
      headers: { 'X-API-KEY' => @user.api_key },
      as: :json

    assert_response :ok

    job_uuid = JSON.parse(response.body)['job_uuid']
    assert_enqueued_with(job: CreateStaticAssetsJob, args: [@other_resource.id, 'https://static.example/images', 'static-assets', { job_uuid: job_uuid }])
  end

  # There is no admin check on this action: a scoped storage credential (plus base_query, which
  # already restricts non-admins to their own organization's resources below) is what gates access
  # now, rather than requiring the caller to be an admin.
  test 'allows a non-admin API key to process their own organization\'s resources' do
    non_admin = User.create!(name: 'Non-Admin API User', email: 'non-admin@example.com', api_key: 'non-admin-key')
    UserOrganization.create!(user: non_admin, organization: @organization)

    post create_static_assets_public_resources_path,
      params: {
        resource_ids: [@resource.uuid],
        base_url: 'https://static.example/images',
        destination: 'static-assets',
        storage: valid_storage_params
      },
      headers: { 'X-API-KEY' => non_admin.api_key },
      as: :json

    assert_response :ok

    job_uuid = JSON.parse(response.body)['job_uuid']
    assert_enqueued_with(job: CreateStaticAssetsJob, args: [@resource.id, 'https://static.example/images', 'static-assets', { job_uuid: job_uuid }])
  end

  test 'still restricts a non-admin API key from another organization\'s resources' do
    non_admin = User.create!(name: 'Non-Admin API User', email: 'non-admin@example.com', api_key: 'non-admin-key')
    UserOrganization.create!(user: non_admin, organization: @organization)

    assert_no_enqueued_jobs only: CreateStaticAssetsJob do
      post create_static_assets_public_resources_path,
        params: {
          resource_ids: [@other_resource.uuid],
          base_url: 'https://static.example/images',
          destination: 'static-assets',
          storage: valid_storage_params
        },
        headers: { 'X-API-KEY' => non_admin.api_key },
        as: :json
    end

    # base_query excludes @other_resource (it belongs to a different organization), so no
    # resources match at all - a 422, not a vacuous 200 with zero resources processed.
    assert_response :unprocessable_entity
  end

  test 'stores fully-specified storage credentials on the job' do
    post create_static_assets_public_resources_path,
      params: {
        resource_ids: [@resource.uuid],
        base_url: 'https://static.example/images',
        destination: 'static-assets',
        storage: {
          bucket: 'scoped-bucket',
          access_key_id: 'scoped-id',
          secret_access_key: 'scoped-secret',
          session_token: 'scoped-token'
        }
      },
      headers: { 'X-API-KEY' => @user.api_key },
      as: :json

    assert_response :ok

    job = Job.find_by(uuid: JSON.parse(response.body)['job_uuid'])
    assert_equal(
      {
        'bucket' => 'scoped-bucket',
        'access_key_id' => 'scoped-id',
        'secret_access_key' => 'scoped-secret',
        'session_token' => 'scoped-token'
      },
      job.extra['storage_credentials']
    )
  end

  test 'session_token is optional on otherwise-complete storage credentials' do
    post create_static_assets_public_resources_path,
      params: {
        resource_ids: [@resource.uuid],
        base_url: 'https://static.example/images',
        destination: 'static-assets',
        storage: valid_storage_params
      },
      headers: { 'X-API-KEY' => @user.api_key },
      as: :json

    assert_response :ok
  end

  test 'rejects partially-specified storage credentials' do
    assert_no_enqueued_jobs only: CreateStaticAssetsJob do
      post create_static_assets_public_resources_path,
        params: {
          resource_ids: [@resource.uuid],
          base_url: 'https://static.example/images',
          destination: 'static-assets',
          storage: { bucket: 'scoped-bucket' }
        },
        headers: { 'X-API-KEY' => @user.api_key },
        as: :json
    end

    assert_response :unprocessable_entity
  end

  test 'rejects a request that omits storage credentials entirely' do
    assert_no_enqueued_jobs only: CreateStaticAssetsJob do
      post create_static_assets_public_resources_path,
        params: {
          resource_ids: [@resource.uuid],
          base_url: 'https://static.example/images',
          destination: 'static-assets'
        },
        headers: { 'X-API-KEY' => @user.api_key },
        as: :json
    end

    assert_response :unprocessable_entity
  end

  test 'retrying the same batch under the same job_uuid does not inflate total_count' do
    job_uuid = SecureRandom.uuid

    2.times do
      post create_static_assets_public_resources_path,
        params: {
          resource_ids: [@resource.uuid],
          base_url: 'https://static.example/images',
          destination: 'static-assets',
          storage: valid_storage_params,
          job_uuid: job_uuid
        },
        headers: { 'X-API-KEY' => @user.api_key },
        as: :json

      assert_response :ok
    end

    job = Job.find_by(uuid: job_uuid)
    assert_equal 1, job.total_count
    assert_equal 1, job.job_items.count
  end

  test 'records the creating user on a newly-created job' do
    post create_static_assets_public_resources_path,
      params: {
        resource_ids: [@resource.uuid],
        base_url: 'https://static.example/images',
        destination: 'static-assets',
        storage: valid_storage_params
      },
      headers: { 'X-API-KEY' => @user.api_key },
      as: :json

    assert_response :ok

    job_uuid = JSON.parse(response.body)['job_uuid']
    assert_equal @user.id, Job.find_by(uuid: job_uuid).user_id
  end

  test 'rejects reuse of a job_uuid owned by a different user' do
    other_user = User.create!(name: 'Other API User', email: 'other-api-user@example.com', api_key: 'other-valid-api-key', admin: true)
    job_uuid = SecureRandom.uuid
    Job.create!(uuid: job_uuid, status: Job::STATUS_PROCESSING, user: other_user)

    assert_no_enqueued_jobs only: CreateStaticAssetsJob do
      post create_static_assets_public_resources_path,
        params: {
          resource_ids: [@resource.uuid],
          base_url: 'https://static.example/images',
          destination: 'static-assets',
          storage: valid_storage_params,
          job_uuid: job_uuid
        },
        headers: { 'X-API-KEY' => @user.api_key },
        as: :json
    end

    assert_response :forbidden
    # Neither resources nor credentials should be touched on a job this caller doesn't own.
    assert_equal 0, Job.find_by(uuid: job_uuid).job_items.count
    assert_nil Job.find_by(uuid: job_uuid).extra['storage_credentials']
  end

  test 'rejects reuse of a job_uuid with no recorded owner (pre-existing job created before ownership was tracked)' do
    job_uuid = SecureRandom.uuid
    Job.create!(uuid: job_uuid, status: Job::STATUS_PROCESSING, user: nil)

    assert_no_enqueued_jobs only: CreateStaticAssetsJob do
      post create_static_assets_public_resources_path,
        params: {
          resource_ids: [@resource.uuid],
          base_url: 'https://static.example/images',
          destination: 'static-assets',
          storage: valid_storage_params,
          job_uuid: job_uuid
        },
        headers: { 'X-API-KEY' => @user.api_key },
        as: :json
    end

    assert_response :forbidden
  end

  private

  def valid_storage_params
    { bucket: 'scoped-bucket', access_key_id: 'scoped-id', secret_access_key: 'scoped-secret' }
  end
end
