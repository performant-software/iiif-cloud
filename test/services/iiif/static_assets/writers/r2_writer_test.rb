require 'test_helper'

class R2WriterTest < ActiveSupport::TestCase
  class FakeS3Client
    Call = Struct.new(:method, :args)

    attr_reader :calls
    attr_accessor :existing_keys

    def initialize
      @calls = []
      @existing_keys = []
    end

    def put_object(bucket:, key:, body:)
      @calls << Call.new(:put_object, { bucket: bucket, key: key, body: body })
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
    @original_r2_env = %w[R2_BUCKET R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY R2_ENDPOINT].index_with { |key| ENV[key] }

    ENV['R2_BUCKET'] = 'test-bucket'
    ENV['R2_ACCESS_KEY_ID'] = 'id'
    ENV['R2_SECRET_ACCESS_KEY'] = 'secret'
    ENV['R2_ENDPOINT'] = 'https://example.r2.cloudflarestorage.com'

    @fake_client = FakeS3Client.new
    fake_client = @fake_client
    @client_singleton = Aws::S3::Client.singleton_class
    @original_new = @client_singleton.instance_method(:new)
    @client_singleton.define_method(:new) { |*_args, **_kwargs| fake_client }
  end

  teardown do
    @client_singleton.define_method(:new, @original_new)
    @original_r2_env.each { |key, value| ENV[key] = value }
  end

  test 'writes objects under the given prefix' do
    writer = Iiif::StaticAssets::Writers::R2Writer.new('resources/42')
    writer.write('info.json', '{}')

    call = @fake_client.calls.first
    assert_equal :put_object, call.method
    assert_equal 'test-bucket', call.args[:bucket]
    assert_equal 'resources/42/info.json', call.args[:key]
    assert_equal '{}', call.args[:body]
  end

  test 'copy issues a server-side copy with an escaped source key' do
    writer = Iiif::StaticAssets::Writers::R2Writer.new('resources/42')
    writer.copy('full/64,64/0/default.jpg', 'full/64,/0/default.jpg')

    call = @fake_client.calls.first
    assert_equal :copy_object, call.method
    assert_equal 'test-bucket/resources/42/full/64%2C64/0/default.jpg', call.args[:copy_source]
    assert_equal 'resources/42/full/64,/0/default.jpg', call.args[:key]
  end
end
