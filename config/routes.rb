# config/routes.rb
Rails.application.routes.draw do
  # to reverse the unu cloud requests
  resources :unu_requests, only: [ :index, :show ]
  constraints subdomain: "unu.cloud" do
    match "*path", to: "unu#handle", via: :all
  end

  devise_for :users

  namespace :api do
    namespace :v1 do
      resources :scooters, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          post :lock
          post :unlock
          post :blinkers
          post :honk
          post :play_sound
          post :open_seatbox
          post :ping
          post :update_firmware
          post :get_state

          post :generate_token
        end
        resources :trips, only: [ :index, :create ] do
          collection do
            post :end
          end
        end
      end
      get "scooters/:vin/config", to: "scooters#config_for_vin", as: "config_for_vin"

      post "mosquitto/auth", to: "mosquitto_auth#authenticate"
      post "mosquitto/acl", to: "mosquitto_auth#authorize"
    end
  end

  resource :account, only: [ :show, :edit, :update, :destroy ] do
    resources :api_tokens, only: [ :new, :create, :destroy ], controller: "accounts/api_tokens"
  end

  # Onboarding flow
  get "onboarding", to: "onboarding#index"
  post "onboarding/create_scooter"
  get "onboarding/config"

  root "dashboard#index"
  get "dashboard/index"

  resources :scooters do
    member do
      post :lock
      post :unlock
      post :blinkers
      post :honk
      post :play_sound
      post :open_seatbox
      post :ping
      post :update_firmware
      post :get_state

      get :show_token_management
    end

    # API token management
    resources :api_tokens, only: [ :create ] do
      collection do
        get :download_config
      end
    end
  end

  resources :trips, only: [ :index, :show ]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
