namespace :iiif do

  desc 'Creates a new IIIF manifest for all resources'
  task create_manifests: :environment do
    Resource.all.in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        CreateManifestJob.perform_now(resource_id)
      end
    end
  end

end