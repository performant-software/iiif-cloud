module Iiif
  class Server

    def clear_cache(key)
      auth = {
        username: ENV['CANTALOUPE_API_USERNAME'],
        password: ENV['CANTALOUPE_API_PASSWORD']
      }

      body = {
        verb: 'PurgeItemFromCache',
        identifier: key
      }

      parse_response HTTParty.post("#{ENV['IIIF_HOST']}/tasks", body: body.to_json, basic_auth: auth)
    end

    private

    def parse_response(response)
      [response.success?, response['exception'] || response['message'] || response['errors']]
    end

  end
end