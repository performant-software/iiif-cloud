require 'rack/session/cookie'
require 'sidekiq/web'

# Enable Rack session middleware only for Sidekiq Web UI
Sidekiq::Web.use Rack::Session::Cookie, secret: Rails.application.credentials.secret_key_base, same_site: :lax, max_age: 86400

# Add Basic Authentication for Security
Sidekiq::Web.use Rack::Auth::Basic  do |email, password|
  user = User.find_by(email:,)
  user.present? && user.admin? && user.authenticate(password)
end

Rails.application.routes.draw do
  mount JwtAuth::Engine, at: '/auth'
  mount Sidekiq::Web => '/sidekiq'
  mount UserDefinedFields::Engine, at: '/user_defined_fields'

  namespace :api do
    get 'dashboard/heap', to: 'dashboard#heap'
    get 'dashboard/status', to: 'dashboard#status'

    resources :organizations
    resources :projects
    resources :resources do
      post :clear_cache, on: :member
      post :convert, on: :member
      post :upload, on: :collection
    end
    resources :users

    # Authentication
    post '/auth/login', to: 'authentication#login'
  end

  namespace :public do
    namespace :presentation do
      post :collection
      post :manifest
    end

    resources :resources, only: [:index, :create, :show, :destroy, :update] do
      member do
        get :content
        get :download
        get :iiif
        get :info
        get :inline
        get :manifest
        get :preview
        get :thumbnail
      end
    end

    get 'resources/:id/:region/:size/:rotation/:quality', to: 'resources#image_api', defaults: { format: 'jpg' }
  end

  # Default route for static front-end
  get '*path', to: "application#fallback_index_html", constraints: -> (request) do
    !request.xhr? && request.format.html?
  end
end
