Rails.application.routes.draw do
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
