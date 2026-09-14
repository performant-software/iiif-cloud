class DeleteHlsJob < ApplicationJob
  def perform(prefix)
    raise ArgumentError, "Invalid HLS prefix: #{prefix.inspect}" unless prefix.to_s.include?("#{ProcessVideoJob::HLS_DIRECTORY}/")

    ActiveStorage::Blob.service.delete_prefixed("#{prefix}/")
  end
end
