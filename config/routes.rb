Rails.application.routes.draw do
  resources :suppliers
  resources :products
  resources :orders do
    member do
      post :send_to_supplier
      get  :download_eml
    end
    resources :order_lines, only: [:create, :destroy]
  end
  root to: "orders#index"

  # Reveal health status on /up that returns 200 if the app boots without exceptions, 404 otherwise.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
