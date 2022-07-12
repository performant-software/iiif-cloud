module Attachable
  extend ActiveSupport::Concern

  # Includes
  include Rails.application.routes.url_helpers

  included do
    @attachments = []

    # Callbacks
    before_save :delete_attachments

    def delete_attachments
      self.class.list_attachments&.each do |name|
        next unless self.send("#{name}_remove")

        attachment = self.send(name)
        return unless attachment.attached?

        attachment.purge
      end
    end
  end

  class_methods do

    # This method overrides model#has_one_attached in order to facilitate generating a <name>_url method for easily
    # accessing the attachment URL in serializers.
    def has_one_attached(name, dependent: :purge_later)
      super
      generate_url_method name
      generate_remove_method name
      @attachments << name
    end

    # This method overrides model#has_many_attached in order to facilitate generating a <name>_url method for easily
    # accessing the attachment URL in serializers.
    def has_many_attached(name, dependent: :purge_later)
      super
      generate_url_method name
      generate_remove_method name
      @attachments << name
    end

    def generate_remove_method(name)
      attribute = "#{name}_remove"

      # Allow parameter
      allow_params name.to_sym, attribute.to_sym

      # Generate setter method
      define_method("#{attribute}=".to_sym) do |value|
        instance_variable_set("@#{attribute}", value)
      end

      # Generate getter method
      define_method(attribute.to_sym) do
        instance_variable_get("@#{attribute}")
      end
    end

    def generate_url_method(name)
      define_method("#{name}_url") do
        attachment = self.send(name)
        return nil unless attachment.attached?

        "#{ENV['IIIF_HOST']}/iiif/3/#{attachment.key}/full/500,/0/default.jpg"
      end

      define_method("#{name}_download_url") do
        attachment = self.send(name)
        return nil unless attachment.attached?

        attachment.service_url({ disposition: 'attachment' })
      end

      define_method("#{name}_thumbnail_url") do
        attachment = self.send(name)
        return nil unless attachment.attached?

        "#{ENV['IIIF_HOST']}/iiif/3/#{attachment.key}/square/250,250/0/default.jpg"
      end
    end

    def attachment_preloads
      @attachments.map{ |a| { "#{a}_attachment".to_sym => :blob } }
    end

    def list_attachments
      @attachments
    end
  end

end
