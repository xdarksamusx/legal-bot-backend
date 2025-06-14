Rails.application.routes.draw do
  get "home/index"
  get "/check", to: "home#check"
  resources :disclaimers
  get '/dashboard', to: 'dashboard#index'
 
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  

    resources :disclaimers, only: [:create, :show] do
      member do 
      patch :continue

      get :download_pdf
      get :download_text_file
    end
  end

   # get "/users/current", to: "users#current"

  namespace :api do 
    post 'generate_disclaimer', to: 'openai#generate'

  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "disclaimers#index"
end
