require 'test_helper'

class Public::StaticManifestsControllerTest < ActionDispatch::IntegrationTest
  class FakeS3Client
    Call = Struct.new(:method, :args)

    attr_reader :calls

    def initialize
      @calls = []
    end

    def put_object(bucket:, key:, body:)
      @calls << Call.new(:put_object, { bucket: bucket, key: key, body: body })
    end
  end

  setup do
    ENV['R2_BUCKET'] = 'test-bucket'
    ENV['R2_ACCESS_KEY_ID'] = 'id'
    ENV['R2_SECRET_ACCESS_KEY'] = 'secret'
    ENV['R2_ENDPOINT'] = 'https://example.r2.cloudflarestorage.com'

    @user = User.create!(name: 'API User', email: 'api-user@example.com', api_key: 'valid-api-key')

    @fake_client = FakeS3Client.new
    fake_client = @fake_client
    @client_singleton = Aws::S3::Client.singleton_class
    @original_new = @client_singleton.instance_method(:new)
    @client_singleton.define_method(:new) { |*_args, **_kwargs| fake_client }
  end

  teardown do
    @client_singleton.define_method(:new, @original_new)
  end

  test 'requires a valid API key' do
    post public_static_manifests_path, params: {
      destination: 'static-manifests',
      path: 'works/some-uuid/iiif/presentation/v3/manifest.json',
      manifest: { id: 'https://static.example/manifest.json' }
    }, as: :json

    assert_response :unauthorized
  end

  test 'requires destination, path, and manifest' do
    post public_static_manifests_path,
      params: { destination: 'static-manifests' },
      headers: { 'X-API-KEY' => @user.api_key },
      as: :json

    assert_response :unprocessable_entity
  end

  test 'writes the manifest JSON to the given destination and path' do
    post public_static_manifests_path,
      params: {
        destination: 'static-manifests',
        path: 'works/some-uuid/iiif/presentation/v3/manifest.json',
        manifest: { id: 'https://static.example/manifest.json', type: 'Manifest' }
      },
      headers: { 'X-API-KEY' => @user.api_key },
      as: :json

    assert_response :ok

    call = @fake_client.calls.first
    assert_equal :put_object, call.method
    assert_equal 'test-bucket', call.args[:bucket]
    assert_equal 'static-manifests/works/some-uuid/iiif/presentation/v3/manifest.json', call.args[:key]

    body = JSON.parse(call.args[:body])
    assert_equal 'https://static.example/manifest.json', body['id']
    assert_equal 'Manifest', body['type']
  end
end
