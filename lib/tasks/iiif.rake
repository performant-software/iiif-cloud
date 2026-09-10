namespace :iiif do

  # Splits a resource query by the source content's MIME type, without loading every Resource.
  def conversion_content_type_breakdown(query, source_attachment_name: 'content')
    content_types = query
      .joins("INNER JOIN active_storage_attachments source_attachments ON source_attachments.record_id = resources.id AND source_attachments.record_type = 'Resource' AND source_attachments.name = '#{source_attachment_name}'")
      .joins('INNER JOIN active_storage_blobs source_blobs ON source_blobs.id = source_attachments.blob_id')
      .pluck('source_blobs.content_type')

    image_count = content_types.count { |content_type| content_type.to_s.start_with?('image/') }
    pdf_count = content_types.count { |content_type| content_type == 'application/pdf' }

    { total: content_types.size, images: image_count, pdfs: pdf_count, other: content_types.size - image_count - pdf_count }
  end

  def print_conversion_breakdown(breakdown, verb:)
    puts "#{verb} #{breakdown[:total]} resources for conversion:"
    puts "  images: #{breakdown[:images]}"
    puts "  pdfs: #{breakdown[:pdfs]}"
    puts "  other: #{breakdown[:other]}"
  end

  # Reports the resources a query would queue and asks for confirmation before enqueuing jobs.
  # Set CONFIRM=true to skip the prompt for non-interactive runs (e.g. CI, scheduled tasks).
  def confirm_conversion_queue(query, source_attachment_name: 'content')
    breakdown = conversion_content_type_breakdown(query, source_attachment_name: source_attachment_name)
    print_conversion_breakdown(breakdown, verb: 'Found')

    return false if breakdown[:total].zero?
    return true if ENV['CONFIRM'] == 'true'

    print 'Continue and queue these jobs for conversion? [y/N] '
    $stdout.flush
    %w[y yes].include?($stdin.gets.to_s.strip.downcase)
  end

  desc 'Converts the source images to pyramidal TIFFs for all resources'
  task convert_images: :environment do
    query = Resource.with_attachment('content') do |subquery|
      subquery
        .joins(:blob)
        .where('active_storage_blobs.byte_size > ?', 0)
        .where('active_storage_blobs.content_type ILIKE \'%image%\' OR active_storage_blobs.content_type = \'application/pdf\'')
    end

    next puts('Aborted.') unless confirm_conversion_queue(query)

    query.in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        ConvertImageJob.perform_later(resource_id)
      end
    end
  end

  desc 'Converts the source images to pyramidal TIFFs for resources with no converted content'
  task convert_images_empty: :environment do
    # Images convert into content_converted; PDFs convert into content_converted_pages, so
    # a resource only counts as "unconverted" if neither is present.
    query = Resource
              .without_attachment('content_converted')
              .without_attachment('content_converted_pages')
              .with_attachment('content') do |subquery|
                subquery
                  .joins(:blob)
                  .where('active_storage_blobs.byte_size > ?', 0)
                  .where('active_storage_blobs.content_type ILIKE \'%image%\' OR active_storage_blobs.content_type = \'application/pdf\'')
              end

    next puts('Aborted.') unless confirm_conversion_queue(query)

    query.in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        ConvertImageJob.perform_later(resource_id)
      end
    end
  end

  desc ''
  task convert_images_by_colorspace: :environment do
    # Parse the arguments
    options = {}

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: rake iiif:convert_images_by_colorspace [options]'
      opts.on('-c', '--colorspace ARG', 'Image colorspace') { |colorspace| options[:colorspace] = colorspace }
    end

    args = opt_parser.order!(ARGV) {}
    opt_parser.parse!(args)

    if options[:colorspace].blank?
      puts 'Please specify a colorspace...'
      exit 0
    end

    query = Resource.where("(exif::json)->>'colorspace' = ?", options[:colorspace])

    next puts('Aborted.') unless confirm_conversion_queue(query)

    query.in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        ConvertImageJob.perform_later(resource_id)
      end
    end
  end

  desc 'Converts the source images to pyramidal TIFFs for resources created in a given date range'
  task convert_images_by_date_range: :environment do
    # Parse the arguments
    options = {}

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: rake iiif:convert_images_by_date_range [options]'
      opts.on('--after after_date', 'After this date') { |after| options[:after] = after }
      opts.on('--before before_date', 'Before this date') { |before| options[:before] = before }
    end

    args = opt_parser.order!(ARGV) {}
    opt_parser.parse!(args)

    if options[:after].blank? && options[:before].blank?
      puts 'Please specify at least one date (--after and/or --before)...'
      exit 0
    end

    # Filter on the source content's blob so both images and PDFs are matched by creation date.
    query = Resource.with_attachment('content') do |subquery|
      subquery = subquery
        .joins(:blob)
        .where('active_storage_blobs.byte_size > ?', 0)
        .where('active_storage_blobs.content_type ILIKE \'%image%\' OR active_storage_blobs.content_type = \'application/pdf\'')

      subquery = subquery.where('active_storage_blobs.created_at > ?', options[:after]) if options[:after].present?
      subquery = subquery.where('active_storage_blobs.created_at < ?', options[:before]) if options[:before].present?

      subquery
    end

    next puts('Aborted.') unless confirm_conversion_queue(query)

    total_queued = 0
    query.in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        ConvertImageJob.perform_later(resource_id)
        total_queued += 1
      end
    end

    puts "Queued #{total_queued} resources for conversion"
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

    next puts('Aborted.') unless confirm_conversion_queue(query)

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
    query = Resource
              .with_attachment('content') do |subquery|
                subquery
                  .joins(:blob)
                  .where('active_storage_blobs.byte_size > ?', 0)
                  .where('active_storage_blobs.content_type ILIKE \'%image%\'')
              end

    query.in_batches do |resources|
      resources.pluck(:id).each do |resource_id|
        ExtractExifJob.perform_later(resource_id)
      end
    end
  end

  desc 'Extracts the EXIF data from resources with no EXIF data'
  task extract_exif_empty: :environment do
    query = Resource
              .where(exif: nil)
              .with_attachment('content') do |subquery|
                subquery
                  .joins(:blob)
                  .where('active_storage_blobs.byte_size > ?', 0)
                  .where('active_storage_blobs.content_type ILIKE \'%image%\'')
              end

    query.in_batches do |resources|
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