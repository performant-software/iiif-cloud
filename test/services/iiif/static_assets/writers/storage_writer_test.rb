require 'test_helper'

class StorageWriterTest < ActiveSupport::TestCase
  attr_accessor :client_constructor_kwargs

  class FakeS3Client
    Call = Struct.new(:method, :args)

    attr_reader :calls
    attr_accessor :existing_keys

    def initialize
      @calls = []
      @existing_keys = []
    end

    def put_object(bucket:, key:, body:, content_type:)
      @calls << Call.new(:put_object, { bucket: bucket, key: key, body: body, content_type: content_type })
    end

    def head_object(bucket:, key:)
      @calls << Call.new(:head_object, { bucket: bucket, key: key })
      raise Aws::S3::Errors::NotFound.new(nil, 'not found') unless @existing_keys.include?(key)
    end

    def copy_object(bucket:, copy_source:, key:)
      @calls << Call.new(:copy_object, { bucket: bucket, copy_source: copy_source, key: key })
    end
  end

  setup do
    @original_env = %w[STATIC_STORAGE_BUCKET STATIC_STORAGE_ACCESS_KEY_ID STATIC_STORAGE_SECRET_ACCESS_KEY STATIC_STORAGE_ENDPOINT STATIC_STORAGE_REGION].index_with { |key| ENV[key] }

    ENV['STATIC_STORAGE_BUCKET'] = 'env-bucket'
    ENV['STATIC_STORAGE_ACCESS_KEY_ID'] = 'env-id'
    ENV['STATIC_STORAGE_SECRET_ACCESS_KEY'] = 'env-secret'
    ENV['STATIC_STORAGE_ENDPOINT'] = 'https://example.r2.cloudflarestorage.com'
    ENV.delete('STATIC_STORAGE_REGION')

    @fake_client = FakeS3Client.new
    @client_constructor_kwargs = nil
    fake_client = @fake_client
    @client_singleton = Aws::S3::Client.singleton_class
    @original_new = @client_singleton.instance_method(:new)
    client_constructor_kwargs = method(:client_constructor_kwargs=)
    @client_singleton.define_method(:new) { |*_args, **kwargs| client_constructor_kwargs.call(kwargs); fake_client }
  end

  teardown do
    @client_singleton.define_method(:new, @original_new)
    @original_env.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  test 'requires bucket, access_key_id, and secret_access_key, with no fallback' do
    assert_raises(ArgumentError) { Iiif::StaticAssets::Writers::StorageWriter.new('resources/42') }
  end

  test 'always reads endpoint and region from this process\'s own environment, never from params' do
    Iiif::StaticAssets::Writers::StorageWriter.new(
      'resources/42', bucket: 'b', access_key_id: 'id', secret_access_key: 'secret'
    )

    assert_equal 'https://example.r2.cloudflarestorage.com', client_constructor_kwargs[:endpoint]
    assert_equal 'auto', client_constructor_kwargs[:region]
  end

  test 'defaults region to "auto" when STATIC_STORAGE_REGION is unset' do
    Iiif::StaticAssets::Writers::StorageWriter.new(
      'resources/42', bucket: 'b', access_key_id: 'id', secret_access_key: 'secret'
    )

    assert_equal 'auto', client_constructor_kwargs[:region]
  end

  test 'uses STATIC_STORAGE_REGION when set' do
    ENV['STATIC_STORAGE_REGION'] = 'us-east-1'

    Iiif::StaticAssets::Writers::StorageWriter.new(
      'resources/42', bucket: 'b', access_key_id: 'id', secret_access_key: 'secret'
    )

    assert_equal 'us-east-1', client_constructor_kwargs[:region]
  end

  test 'passes through an explicit session_token, defaulting to nil (omitted) otherwise' do
    Iiif::StaticAssets::Writers::StorageWriter.new(
      'resources/42', bucket: 'b', access_key_id: 'id', secret_access_key: 'secret', session_token: 'temp-token'
    )
    assert_equal 'temp-token', client_constructor_kwargs[:session_token]

    Iiif::StaticAssets::Writers::StorageWriter.new(
      'resources/42', bucket: 'b', access_key_id: 'id', secret_access_key: 'secret'
    )
    assert_not client_constructor_kwargs.key?(:session_token)
  end

  test 'from_env builds a writer using this process\'s own environment-configured credentials' do
    Iiif::StaticAssets::Writers::StorageWriter.from_env('resources/42')

    assert_equal 'env-id', client_constructor_kwargs[:access_key_id]
    assert_equal 'env-secret', client_constructor_kwargs[:secret_access_key]
  end

  test 'from_env raises if a required environment variable is missing' do
    ENV.delete('STATIC_STORAGE_BUCKET')

    assert_raises(KeyError) { Iiif::StaticAssets::Writers::StorageWriter.from_env('resources/42') }
  end

  test 'writes objects under the given prefix, using the given bucket' do
    writer = Iiif::StaticAssets::Writers::StorageWriter.new(
      'resources/42', bucket: 'scoped-bucket', access_key_id: 'id', secret_access_key: 'secret'
    )
    writer.write('info.json', '{}')

    call = @fake_client.calls.first
    assert_equal :put_object, call.method
    assert_equal 'scoped-bucket', call.args[:bucket]
    assert_equal 'resources/42/info.json', call.args[:key]
    assert_equal '{}', call.args[:body]
    assert_equal 'application/json', call.args[:content_type]
  end

  test 'sets an image/jpeg content type for jpg assets' do
    writer = Iiif::StaticAssets::Writers::StorageWriter.new(
      'resources/42', bucket: 'b', access_key_id: 'id', secret_access_key: 'secret'
    )
    writer.write('full/max/0/default.jpg', 'bytes')

    call = @fake_client.calls.first
    assert_equal 'image/jpeg', call.args[:content_type]
  end

  test 'copy issues a server-side copy with an escaped source key' do
    writer = Iiif::StaticAssets::Writers::StorageWriter.new(
      'resources/42', bucket: 'scoped-bucket', access_key_id: 'id', secret_access_key: 'secret'
    )
    writer.copy('full/64,64/0/default.jpg', 'full/64,/0/default.jpg')

    call = @fake_client.calls.first
    assert_equal :copy_object, call.method
    assert_equal 'scoped-bucket/resources/42/full/64%2C64/0/default.jpg', call.args[:copy_source]
    assert_equal 'resources/42/full/64,/0/default.jpg', call.args[:key]
  end
end
