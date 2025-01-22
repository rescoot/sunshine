Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :telemetry, only: [ :create ]
      resources :trips, only: [] do
        collection do
          post :start
          post :end
        end
      end
      post "command", to: "commands#receive"
    end
  end

  devise_for :users

  root "dashboard#index"
  get "dashboard/index"

  resources :scooters do
    member do
      post :lock
      post :unlock
      post :blinkers
      post :honk
      post :play_sound
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
