class Resource < ApplicationRecord
  # Includes
  include Attachable
  include Identifiable
  include UserDefinedFields::Fieldable

  # Relationships
  belongs_to :project

  # Read only attributes
  attr_readonly :storage_key

  # Resourceable parameters
  allow_params :project_id, :name, :content, :metadata, :storage_key

  # Callbacks
  before_save :parse_metadata
  after_create_commit :after_create
  after_update_commit :after_update

  # ActiveStorage
  has_one_attached :content
  has_one_attached :content_converted
  # Page URLs are page-indexed and defined below, so skip the generic (page-unaware) macro-generated ones.
  has_many_attached :content_converted_pages, generate_urls: false

  # Delegates
  delegate :audio?, to: :content
  delegate :image?, to: :content
  delegate :video?, to: :content

  # Fieldable
  resolve_defineable -> (resource) { resource.project }

  # Overload attachable methods
  alias_method :attachable_content_base_url, :content_base_url
  alias_method :attachable_content_preview_url, :content_preview_url
  alias_method :attachable_content_iiif_url, :content_iiif_url
  alias_method :attachable_content_image_api_url, :content_image_api_url
  alias_method :attachable_content_info_url, :content_info_url
  alias_method :attachable_content_thumbnail_url, :content_thumbnail_url

  def self.with_attachment(name)
    subquery = attachment_subquery(name)
    subquery = yield subquery if block_given?

    where(subquery.arel.exists)
  end

  def self.without_attachment(name)
    subquery = attachment_subquery(name)
    subquery = yield subquery if block_given?

    where.not(subquery.arel.exists)
  end

  def content_base_url
    # For multi-page PDFs, this should return the info for the whole PDF (including page count)
    if content_converted_pages.attached?
      return "#{ENV['IIIF_HOST_DOCKER'] || ENV['IIIF_HOST']}/iiif/3/#{CGI.escape(content.key)}"
    end

    return attachable_content_base_url unless content_converted.attached?

    "#{ENV['IIIF_HOST_DOCKER'] || ENV['IIIF_HOST']}/iiif/3/#{CGI.escape(content_converted.key)}"
  end

  def content_iiif_url(page_number = 1)
    return attachable_content_iiif_url(page_number) if iiif?

    nil
  end

  def content_info_url(page_number = 1)
    return attachable_content_info_url(page_number) if iiif?

    nil
  end

  def content_image_api_url(page_number, region, size, rotation, quality, format)
    return attachable_content_image_api_url(page_number, region, size, rotation, quality, format) if iiif?

    nil
  end

  def content_preview_url
    return attachable_content_preview_url if iiif?

    nil
  end

  def content_thumbnail_url
    return attachable_content_thumbnail_url if iiif?

    nil
  end

  def content_type
    # For multi-page PDFs, return PTIF content type
    return 'image/tiff' if content_converted_pages.attached?
    
    return content.content_type unless content_converted.attached?

    content_converted.content_type
  end

  # IIIF methods for multi-page PDFs
  # These methods provide access to individual page URLs in multi-page conversions

  # Get the base IIIF URL for a specific page in a multi-page PDF
  # @param page_number [Integer] 1-indexed page number
  # @return [String, nil] The base URL for the page, or nil if not found
  def content_converted_pages_base_url(page_number)
    return nil unless content_converted_pages.attached?
    page_number = page_number.to_i
    return nil unless pages_count
    return nil if page_number < 1 || page_number > pages_count

    page = content_converted_pages.to_a.find do |attachment|
      attachment.blob.metadata['original_page_number'].to_i == page_number
    end
    return nil unless page

    "#{ENV['IIIF_HOST_DOCKER'] || ENV['IIIF_HOST']}/iiif/3/#{CGI.escape(page.key)}"
  end

  # Get the full IIIF Image API URL for a specific page in a multi-page PDF
  # @param page_number [Integer] 1-indexed page number
  # @param region [String] IIIF region parameter (default: 'full')
  # @param size [String] IIIF size parameter (default: 'max')
  # @param rotation [String] IIIF rotation parameter (default: '0')
  # @param quality [String] IIIF quality parameter (default: 'default')
  # @param format [String] Image format (default: 'jpg')
  # @return [String, nil] The full IIIF Image API URL, or nil if page not found
  def content_converted_pages_image_api_url(page_number, region = 'full', size = 'max', rotation = '0', quality = 'default', format = 'jpg')
    base_url = content_converted_pages_base_url(page_number)
    return nil unless base_url

    "#{base_url}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
  end

  # Get the IIIF info.json URL for a specific page in a multi-page PDF
  # @param page_number [Integer] 1-indexed page number
  # @return [String, nil] The IIIF info.json URL, or nil if page not found
  def content_converted_pages_info_url(page_number)
    base_url = content_converted_pages_base_url(page_number)
    return nil unless base_url

    "#{base_url}/info.json"
  end

  # Get the IIIF presentation URL for a specific page in a multi-page PDF
  # @param page_number [Integer] 1-indexed page number
  # @return [String, nil] The IIIF presentation URL, or nil if page not found
  def content_converted_pages_iiif_url(page_number)
    base_url = content_converted_pages_base_url(page_number)
    return nil unless base_url

    "#{base_url}/full/max/0/default.jpg"
  end

  # Get the IIIF thumbnail URL for a specific page in a multi-page PDF
  # @param page_number [Integer] 1-indexed page number (default: 1 for first page)
  # @return [String, nil] The IIIF thumbnail URL, or nil if page not found
  def content_converted_pages_thumbnail_url(page_number = 1)
    base_url = content_converted_pages_base_url(page_number)
    return nil unless base_url

    "#{base_url}/square/^!250,250/0/default.jpg"
  end

  # Get the IIIF preview URL for a specific page in a multi-page PDF
  # @param page_number [Integer] 1-indexed page number (default: 1 for first page)
  # @return [String, nil] The IIIF preview URL, or nil if page not found
  def content_converted_pages_preview_url(page_number = 1)
    base_url = content_converted_pages_base_url(page_number)
    return nil unless base_url

    "#{base_url}/full/^!500,500/0/default.jpg"
  end

  # Get all page keys for multi-page PDFs (used for manifest generation)
  # @return [Array<String>] Array of attachment keys in page order, empty array if single-file
  def content_converted_pages_keys
    return [] unless content_converted_pages.attached?
    content_converted_pages.map(&:key)
  end

  # Get the number of pages (only set for multi-page PDFs)
  # @return [Integer, nil] Number of pages for PDFs, nil for images
  def page_count
    pages_count
  end

  def iiif?
    image? || video? || audio? || pdf?
  end

  def pdf?
    content.content_type == 'application/pdf'
  end

  def converted_pages?
    content_converted_pages.attached?
  end

  def converted_single_file?
    content_converted.attached?
  end

  def iiif_conversion
    converted_pages? ? :multi_page : :single_file
  end

  private

  def self.attachment_subquery(name)
    ActiveStorage::Attachment
      .where(ActiveStorage::Attachment.arel_table[:record_id].eq(Resource.arel_table[:id]))
      .where(record_type: Resource.to_s)
      .where(name: name)
  end

  def parse_metadata
    self.metadata = JSON.parse metadata if metadata.instance_of? String
  end

  def after_create
    # Convert the image to a TIFF
    ConvertImageJob.perform_later(self.id)

    # Create the manifest
    CreateManifestJob.perform_later(self.id)

    # Extract EXIF data
    ExtractExifJob.perform_later(self.id)
  end

  def after_update
    if saved_change_to_metadata? || saved_change_to_user_defined?
      # Recreate the manifest if the metadata or user-defined field values were updated
      CreateManifestJob.perform_later(self.id)
    end

    # Only perform the image updates if the content attachment has been updated
    return if !(content.attached? && content.blob.saved_changes?)

    # Convert the image to a TIFF
    ConvertImageJob.perform_later(self.id)

    # Extract EXIF data
    ExtractExifJob.perform_later(self.id)
  end
end
