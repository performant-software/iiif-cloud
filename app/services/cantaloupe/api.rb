module Cantaloupe
  class Api

    def clear_cache(key)
      auth = {
        username: ENV['CANTALOUPE_API_USERNAME'],
        password: ENV['CANTALOUPE_API_PASSWORD']
      }

      body = {
        verb: 'PurgeItemFromCache',
        identifier: key
      }

      HTTParty.post("#{ENV['IIIF_HOST']}/tasks", body: body.to_json, basic_auth: auth)
    end

  end
end