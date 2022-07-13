class Resource < ApplicationRecord
  # Includes
  include Attachable

  # Relationships
  belongs_to :project

  # Resourceable parameters
  allow_params :project_id, :name, :metadata, :content

  # Callbacks
  after_create_commit :convert

  # ActiveStorage
  has_one_attached :content
  has_one_attached :content_converted

  def content_url
    return super unless content.image? && content_converted.attached?

    "#{ENV['IIIF_HOST']}/iiif/3/#{content_converted.key}/full/max/0/default.jpg"
  end

  def content_preview_url
    return super unless content.image? && content_converted.attached?

    "#{ENV['IIIF_HOST']}/iiif/3/#{content_converted.key}/full/500,/0/default.jpg"
  end

  def content_thumbnail_url
    return super unless content.image? && content_converted.attached?

    "#{ENV['IIIF_HOST']}/iiif/3/#{content_converted.key}/square/250,250/0/default.jpg"
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
end
