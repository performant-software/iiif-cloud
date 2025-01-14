# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/public/resources/:id/content', headers: :any, methods: :get
    resource '/public/resources/:id/manifest', headers: :any, methods: :get
    resource '/public/resources/:id/iiif', headers: :any, methods: :get
    resource '/public/resources/:id/info*', headers: :any, methods: :get
    resource '*/rails/active_storage/blobs/redirect/*', headers: :any, methods: :get
  end
end
