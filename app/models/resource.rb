class Resource < ApplicationRecord
  # Includes
  include Attachable

  # Relationships
  belongs_to :project

  # Resourceable parameters
  allow_params :project_id, :name, :metadata, :content

  # Callbacks
  after_create_commit :convert_to_tif

  # ActiveStorage
  has_one_attached :content

  private

  def convert_to_tif
    return unless content.attached? && content.image?

    content.open do |file|
      output_file = "#{File.basename(file.path, '.*')}.tif"
      output_path = File.join(File.dirname(file.path), output_file)

      convert = MiniMagick::Tool::Convert.new
      convert << file.path
      convert << '-define'
      convert << 'tiff:tile-geometry=1024x1024'
      convert << '-depth'
      convert << '8'
      convert << '-compress'
      convert << 'jpeg'
      convert << "ptif:#{output_path}"
      convert.call

      content.attach(
        io: File.open(output_path),
        filename:  output_file,
        content_type: 'image/tiff'
      )
    end
  end
end
