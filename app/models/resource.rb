class Resource < ApplicationRecord
  # Includes
  include Attachable
  include Identifiable
  include UserDefinedFields::Fieldable

  # Relationships
  belongs_to :project

  # Resourceable parameters
  allow_params :project_id, :name, :content

  # Callbacks
  after_create_commit :after_create

  # ActiveStorage
  has_one_attached :content
  has_one_attached :content_converted

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
  alias_method :attachable_content_thumbnail_url, :content_thumbnail_url

  def content_base_url
    return attachable_content_base_url unless content_converted.attached?

    "#{ENV['IIIF_HOST']}/iiif/3/#{content_converted.key}"
  end

  def content_iiif_url(page_number = 1)
    return attachable_content_iiif_url(page_number) if iiif?

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
    return content.content_type unless content_converted.attached?

    content_converted.content_type
  end

  def iiif?
    image? || video? || audio? || pdf?
  end

  def pdf?
    content.content_type == 'application/pdf'
  end

  protected

  def after_create
    # Convert the image to a TIFF
    convert

    # Create the manifest
    create_manifest

    # Extract EXIF data
    extract_exif
  end

  private

  def convert
    return unless image? && content.attached?

    content.open do |file|
      begin
        filepath = Images::Convert.to_tiff(file)
        filename = Images::Convert.filename(content.filename.to_s, 'tif')

        content_converted.attach(
          io: File.open(filepath),
          filename:  filename,
          content_type: 'image/tiff'
        )
      rescue MiniMagick::Error
        # Content cannot be converted
      end
    end
  end

  def create_manifest
    return unless iiif?

    self.manifest = Iiif::Manifest.create(self)

    save
  end


  def extract_exif
    return unless content.attached? && content.image?

    content.open do |file|
      data = Images::Exif.extract(file)

      unless data.nil?
        self.exif = JSON.dump(data)
        save
      end
    end
  end
end
