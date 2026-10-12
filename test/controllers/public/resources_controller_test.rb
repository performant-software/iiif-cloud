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
        destination: 'static-assets'
      },
      headers: { 'X-API-KEY' => @user.api_key },
      as: :json

    assert_response :ok

    job_uuid = JSON.parse(response.body)['job_uuid']
    assert_enqueued_with(job: CreateStaticAssetsJob, args: [@resource.id, 'https://static.example/images', 'static-assets', { job_uuid: job_uuid }])
  end

  test 'admins are not restricted to their own organizations\' resources' do
    post create_static_assets_public_resources_path,
      params: {
        resource_ids: [@other_resource.uuid],
        base_url: 'https://static.example/images',
        destination: 'static-assets'
      },
      headers: { 'X-API-KEY' => @user.api_key },
      as: :json

    assert_response :ok

    job_uuid = JSON.parse(response.body)['job_uuid']
    assert_enqueued_with(job: CreateStaticAssetsJob, args: [@other_resource.id, 'https://static.example/images', 'static-assets', { job_uuid: job_uuid }])
  end

  test 'rejects a non-admin API key' do
    non_admin = User.create!(name: 'Non-Admin API User', email: 'non-admin@example.com', api_key: 'non-admin-key')
    UserOrganization.create!(user: non_admin, organization: @organization)

    assert_no_enqueued_jobs only: CreateStaticAssetsJob do
      post create_static_assets_public_resources_path,
        params: {
          resource_ids: [@resource.uuid],
          base_url: 'https://static.example/images',
          destination: 'static-assets'
        },
        headers: { 'X-API-KEY' => non_admin.api_key },
        as: :json
    end

    assert_response :forbidden
  end

  test 'stores fully-specified r2 credentials on the job' do
    post create_static_assets_public_resources_path,
      params: {
        resource_ids: [@resource.uuid],
        base_url: 'https://static.example/images',
        destination: 'static-assets',
        r2: {
          bucket: 'scoped-bucket',
          access_key_id: 'scoped-id',
          secret_access_key: 'scoped-secret',
          endpoint: 'https://scoped.r2.cloudflarestorage.com'
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
        'endpoint' => 'https://scoped.r2.cloudflarestorage.com'
      },
      job.extra['r2_credentials']
    )
  end

  test 'rejects partially-specified r2 credentials' do
    assert_no_enqueued_jobs only: CreateStaticAssetsJob do
      post create_static_assets_public_resources_path,
        params: {
          resource_ids: [@resource.uuid],
          base_url: 'https://static.example/images',
          destination: 'static-assets',
          r2: { bucket: 'scoped-bucket' }
        },
        headers: { 'X-API-KEY' => @user.api_key },
        as: :json
    end

    assert_response :unprocessable_entity
  end

  test 'omitting r2 entirely leaves the job to fall back on this process\'s own R2 credentials' do
    post create_static_assets_public_resources_path,
      params: {
        resource_ids: [@resource.uuid],
        base_url: 'https://static.example/images',
        destination: 'static-assets'
      },
      headers: { 'X-API-KEY' => @user.api_key },
      as: :json

    assert_response :ok

    job = Job.find_by(uuid: JSON.parse(response.body)['job_uuid'])
    assert_nil job.extra['r2_credentials']
  end
end
