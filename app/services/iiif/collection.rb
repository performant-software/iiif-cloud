module Iiif
  class Collection
    def self.create(id:, label:, items:)
      resources = Resource
                    .preload(Resource.attachment_preloads)
                    .where(uuid: items.map{ |i| i[:thumbnail] }.compact)
                    .inject({}){ |hash, resource| hash[resource.uuid] = resource; hash }

      {
        '@context':"http://iiif.io/api/presentation/3/context.json",
        'id': id,
        'type': 'Collection',
        label: label,
        items: items
                 .sort_by{ |item| item[:label] }
                 .map{ |item| to_item(item, resources[item[:thumbnail]]) }
      }
    end

    private

    def self.to_item(item, resource)
      collection_item = item.slice(:id, :type, :label)

      if resource.present?
        collection_item[:thumbnail] = [{
          id: resource.content_thumbnail_url,
          type: 'Image',
          format: 'image/jpeg',
          width: 250,
          height: 250
        }]
      end

      collection_item
    end
  end
end