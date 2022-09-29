Rails.application.routes.draw do
  mount UserDefinedFields::Engine, at: '/user_defined_fields'

  namespace :api do
    resources :organizations
    resources :projects
    resources :resources do
      post :upload, on: :collection
    end
    resources :users

    # Authentication
    post '/auth/login', to: 'authentication#login'
  end

  namespace :public do
    resources :resources, only: [:create, :show, :destroy, :update]
  end

  # Default route for static front-end
  get '*path', to: "application#fallback_index_html", constraints: -> (request) do
    !request.xhr? && request.format.html?
  end
end
