class Resource < ApplicationRecord
  # Includes
  include Attachable

  # Relationships
  belongs_to :project

  # Resourceable parameters
  allow_params :project_id, :name, :metadata, :content

  # Callbacks
  before_create :set_uuid
  after_create_commit :after_create

  # ActiveStorage
  has_one_attached :content
  has_one_attached :content_converted

  #
  alias_method :attachable_content_url, :content_url
  alias_method :attachable_content_base_url, :content_base_url
  alias_method :attachable_content_preview_url, :content_preview_url
  alias_method :attachable_content_thumbnail_url, :content_thumbnail_url

  def content_url
    return attachable_content_url unless content.image? && content_converted.attached?

    "#{content_base_url}/full/max/0/default.jpg"
  end

  def content_base_url
    return attachable_content_base_url unless content_converted.attached?

    "#{ENV['IIIF_HOST']}/iiif/3/#{content_converted.key}"
  end

  def content_metadata
    return content.metadata unless content_converted.attached?

    content_converted.metadata
  end

  def content_preview_url
    return attachable_content_preview_url unless content.image? && content_converted.attached?

    "#{content_base_url}/full/500,/0/default.jpg"
  end

  def content_thumbnail_url
    return attachable_content_thumbnail_url unless content.image? && content_converted.attached?

    "#{content_base_url}/square/250,250/0/default.jpg"
  end

  def content_type
    return content.content_type unless content_converted.attached?

    content_converted.content_type
  end

  protected

  def after_create
    convert
    create_manifest
  end

  private

  def convert
    return unless content.attached? && content.image?

    content.open do |file|
      filepath = Images::Convert.to_tiff(file)
      filename = Images::Convert.filename(content.filename.to_s, 'tif')

      content_converted.attach(
        io: File.open(filepath),
        filename:  filename,
        content_type: 'image/tiff'
      )
    end
  end

  def create_manifest
    self.manifest = Images::Manifest.create(self)
    save
  end

  def set_uuid
    self.uuid = SecureRandom.uuid
  end
end
