require 'test_helper'

class Public::ResourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: 'Test Organization')
    @other_organization = Organization.create!(name: 'Other Organization')

    @project = Project.create!(organization: @organization, name: 'Test Project')
    @other_project = Project.create!(organization: @other_organization, name: 'Other Project')

    @resource = Resource.create!(project: @project, name: 'Test Resource')
    @other_resource = Resource.create!(project: @other_project, name: 'Other Resource')

    @user = User.create!(name: 'API User', email: 'api-user@example.com', api_key: 'valid-api-key')
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
    assert_enqueued_with(job: CreateStaticAssetsJob, args: [@resource.id, 'https://static.example/images', 'static-assets']) do
      post create_static_assets_public_resources_path,
        params: {
          resource_ids: [@resource.uuid],
          base_url: 'https://static.example/images',
          destination: 'static-assets'
        },
        headers: { 'X-API-KEY' => @user.api_key },
        as: :json
    end

    assert_response :ok
  end

  test 'excludes resources outside the API key user\'s organizations' do
    assert_no_enqueued_jobs only: CreateStaticAssetsJob do
      post create_static_assets_public_resources_path,
        params: {
          resource_ids: [@other_resource.uuid],
          base_url: 'https://static.example/images',
          destination: 'static-assets'
        },
        headers: { 'X-API-KEY' => @user.api_key },
        as: :json
    end

    assert_response :ok
  end
end
