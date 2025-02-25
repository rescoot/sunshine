# config/routes.rb
Rails.application.routes.draw do
  # Static pages
  get "about", to: "pages#about", as: :about
  get "contact", to: "pages#contact", as: :contact
  get "privacy-policy", to: "pages#privacy_policy", as: :privacy_policy
  get "legal-notice", to: "pages#legal_notice", as: :legal_notice
  get "security", to: "pages#security", as: :security

  post "locale", to: "locales#update", as: :locale

  ## turns out the unu "cloud" REST API is used _only_ for activation of the scooter in the warehouse?!
  # # to reverse the unu cloud requests
  # constraints subdomain: "unu.cloud" do
  #   match "/", to: "unu#handle", via: :all
  #   match "*path", to: "unu#handle", via: :all
  # end

  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  # OTP verification routes
  namespace :users do
    resource :otp_verification, only: [ :show, :create ], controller: "otp_verification"
  end

  namespace :admin do
    root to: "dashboard#index"
    resources :feature_flags
    resources :users do
      resources :feature_flags, only: [ :index, :update ], controller: "user_feature_flags" do
        collection do
          patch :update
        end
      end
      resources :achievements, only: [ :index, :create, :destroy ], controller: "user_achievements" do
        collection do
          patch :update
        end
      end
    end
    resources :scooters do
      resources :telemetries, only: [ :index, :show ]
      resources :events, only: [ :index, :show ]
      resources :user_scooters, only: [ :create, :destroy ]
      resource :shell, only: [ :show ] do
        post :execute
      end
    end

    resources :trips
    resources :events, only: [ :index, :show ]
    resources :telemetries, only: [ :index, :show ]
    resources :trips do
      member do
        get :reassign
        post :reassign
      end
    end
    resources :unu_uplink_requests, only: [ :index, :show ]
  end

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
          post :locate
          post :alarm
          post :redis_command
          post :shell_command

          post :generate_token
        end
        resources :trips, only: [ :index, :create ] do
          collection do
            post :end
          end
        end
      end
      get "scooters/:vin/config", to: "scooters#config_for_vin", as: "config_for_vin"

      ## removed due to switch to dynsec plugin
      # post "mosquitto/auth", to: "mosquitto_auth#authenticate"
      # post "mosquitto/acl", to: "mosquitto_auth#authorize"
    end
  end

  resource :account, only: [ :show, :edit, :update, :destroy ] do
    resources :api_tokens, only: [ :new, :create, :destroy ], controller: "accounts/api_tokens"
  end

  # Two-factor authentication
  resource :two_factor_auth, only: [ :new, :create, :destroy ], controller: "two_factor_auth" do
    get :confirm_disable
  end

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
      post :locate
      post :alarm
      post :redis_command
      post :shell_command

      get :show_token_management
    end

    # API token management
    resources :api_tokens, only: [ :create ] do
      collection do
        get :download_config
      end
    end

    # Stats
    resources :statistics, only: [] do
      collection do
        get :ride_statistics
        get :battery_performance
        get :regeneration_efficiency
      end
    end
  end

  resources :trips, only: [ :index, :show ]

  resources :leaderboards, only: [ :index ] do
    collection do
      get :settings
      patch :update_settings
    end
  end

  resources :achievements, only: [ :index ]

  # Onboarding flow
  get "onboarding", to: "onboarding#index"
  post "onboarding/create_scooter"
  get "onboarding/config"

  get "dashboard/index"

  get "vin-decoder", to: "vin_decoder#index"
  get "vin-decoder/:vin", to: "vin_decoder#decode", as: :decode_vin

  get "dashboard", to: "dashboard#index"

  root "pages#index"

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
