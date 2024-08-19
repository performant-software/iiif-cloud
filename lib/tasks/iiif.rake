namespace :iiif do

  desc 'Converts the source images to pyramidal TIFFs for all resources'
  task convert_images: :environment do
    query = Resource.with_attachment('content') do |subquery|
      subquery
        .joins(:blob)
        .where('active_storage_blobs.byte_size > ?', 0)
        .where('active_storage_blobs.content_type ILIKE \'%image%\'')
    end

    query.in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        ConvertImageJob.perform_later(resource_id)
      end
    end
  end

  desc 'Converts the source images to pyramidal TIFFs for resources with no converted content'
  task convert_images_empty: :environment do
    query = Resource
              .without_attachment('content_converted')
              .with_attachment('content') do |subquery|
                subquery
                  .joins(:blob)
                  .where('active_storage_blobs.byte_size > ?', 0)
                  .where('active_storage_blobs.content_type ILIKE \'%image%\'')
              end

    query.in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        ConvertImageJob.perform_later(resource_id)
      end
    end
  end

  desc 'Converts the source images to pyramidal TIFFs for resources by the specified MIME type'
  task convert_images_by_type: :environment do
    # Parse the arguments
    options = {}

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: rake iiif:convert_images_by_type [options]'
      opts.on('-t', '--type ARG', 'Image MIME type') { |type| options[:type] = type }
    end

    args = opt_parser.order!(ARGV) {}
    opt_parser.parse!(args)

    if options[:type].blank?
      puts 'Please specify a MIME type...'
      exit 0
    end

    query = Resource.with_attachment('content') do |subquery|
      subquery
        .joins(:blob)
        .where('active_storage_blobs.byte_size > ?', 0)
        .where('active_storage_blobs.content_type = ?', options[:type])
    end

    query.in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        ConvertImageJob.perform_later(resource_id)
      end
    end
  end

  desc 'Creates a new IIIF manifest for all resources'
  task create_manifests: :environment do
    Resource.all.in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        CreateManifestJob.perform_later(resource_id)
      end
    end
  end

  desc 'Creates a new IIIF manifest for resources with no generated manifest'
  task create_manifests_empty: :environment do
    Resource.where(manifest: nil).in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        CreateManifestJob.perform_later(resource_id)
      end
    end
  end

  desc 'Extracts the EXIF data from all resources'
  task extract_exif: :environment do
    Resource.all.in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        ExtractExifJob.perform_later(resource_id)
      end
    end
  end

  desc 'Extracts the EXIF data from resources with no EXIF data'
  task extract_exif_empty: :environment do
    Resource.where(exif: nil).in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        ExtractExifJob.perform_later(resource_id)
      end
    end
  end

  desc 'Transfers resources from one storage service to another'
  task transfer_resources: :environment do
    # Parse the arguments
    options = {}

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: rake triple_eye_effable:transfer_resources [options]'

      opts.on('--source-service source_service', 'Source Service') do |source_service|
        options[:source_service] = source_service
      end

      opts.on('--destination-service destination_service', 'Destination Service') do |destination_service|
        options[:destination_service] = destination_service
      end
    end

    args = opt_parser.order!(ARGV) {}
    opt_parser.parse!(args)

    if options[:source_service].blank?
      puts 'Please specify a source service...'
      exit 0
    end

    if options[:destination_service].blank?
      puts 'Please specify a destination service...'
      exit 0
    end

    source_service_name = options[:source_service].to_sym
    source_service = ActiveStorage::Blob.services.fetch(source_service_name)

    destination_service_name = options[:destination_service].to_sym
    destination_service = ActiveStorage::Blob.services.fetch(destination_service_name)

    # If we're transferring to the same type of service (e.g. amazon => amazon), we'll keep the name of the
    # original service and assume that the ENV variables will be updated to point to the new service after transfer.
    #
    # If we're transferring to an entirely new service (e.g. amazon => s3Compatible, amazon => local), we'll update
    # the name of the service.
    update_service_name = source_service_name.to_s.gsub('_transfer') != destination_service_name.to_s.gsub('_transfer')

    ActiveStorage::Blob.where(service_name: source_service.name).find_each do |blob|
      # Skip this record if the key does not exist in the source service
      next unless source_service.exist?(blob.key)

      # Skip this record if the key already exists in the destination service
      next if destination_service.exist?(blob.key)

      # Upload the file to the new service
      source_service.open(blob.key, checksum: blob.checksum) do |file|
        destination_service.upload(blob.key, file, checksum: blob.checksum)
      end

      # Update the service name on the blob
      blob.update_columns(service_name: destination_service.name) if update_service_name
    end
  end

end