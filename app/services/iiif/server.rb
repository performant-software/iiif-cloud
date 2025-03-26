module Iiif
  class Server

    def clear_cache(key)
      body = {
        verb: 'PurgeItemFromCache',
        identifier: key
      }

      parse_response HTTParty.post("#{ENV['IIIF_HOST']}/tasks", body: body.to_json, basic_auth: basic_auth)
    end

    def health
      parse_response HTTParty.get("#{ENV['IIIF_HOST']}/health")
    end

    def status
      parse_response HTTParty.get("#{ENV['IIIF_HOST']}/status", basic_auth: basic_auth)
    end

    private

    def basic_auth
      {
        username: ENV['CANTALOUPE_API_USERNAME'],
        password: ENV['CANTALOUPE_API_PASSWORD']
      }
    end

    def parse_response(response)
      if response.body.nil? || response.body.empty?
        body = '{}'
      else
        body = response.body
      end

      {
        success?: response.success?,
        data: JSON.parse(body, symbolize_names: true),
        errors: response['exception'] || response['message'] || response['errors']
      }
    end

  end
end