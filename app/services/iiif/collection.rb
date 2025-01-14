module Iiif
  class Collection
    def self.create(id:, label:, items:)
      resources = Resource
                    .preload(Resource.attachment_preloads)
                    .where(uuid: items.map{ |i| i[:thumbnail] }.compact)
                    .inject({}){ |hash, resource| hash[resource.uuid] = resource; hash }

      {
        '@context':"http://iiif.io/api/presentation/3/context.json",
        id: id,
        type: 'Collection',
        label: {
          en: [label]
        },
        items: items
                 .sort_by{ |item| item[:label] }
                 .map{ |item| to_item(item, resources[item[:thumbnail]]) }
      }
    end

    private

    def self.base_url(resource)
      "#{ENV['HOSTNAME']}/public/resources/#{resource.uuid}"
    end

    def self.to_item(item, resource)
      collection_item = item.slice(:id, :type)

      item_count = item['item_count'].to_i
      label = item['label']

      collection_item['item_count'] = item_count
      collection_item['label'] = {
        en: [label]
      }

      if resource.present?
        collection_item[:thumbnail] = [{
          id: "#{base_url(resource)}/thumbnail",
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