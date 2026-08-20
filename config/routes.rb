Rails.application.routes.draw do
  resources :suppliers
  resources :products
  resources :chantiers, only: [ :index, :show ]
  resources :orders do
    member do
      post :send_to_supplier
      post :resubmit_approval
      get  :download_eml
    end
    resources :order_lines, only: [ :create, :destroy ]
  end
  namespace :api do
    resources :orders, only: [ :create, :index ] do
      collection { post :preview_pdf; get :next_number }
    end
    resources :products, only: [ :index ]
    resources :devis_imports, only: [ :create ] do
      collection { post :confirm_products }
    end
    get   "nomenclature",     to: "nomenclature#index"
    patch "nomenclature/:id", to: "nomenclature#update"
    get :me, to: "sessions#me"
  end

  namespace :admin do
    resources :users, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      member { post :resend_welcome }
    end
    resources :chantiers, only: [ :index, :new, :create, :edit, :update, :destroy ]
  end

  get    "login",           to: "sessions#new",           as: :login
  post   "login",           to: "sessions#create"
  delete "logout",          to: "sessions#destroy",        as: :logout
  get    "signup",          to: "registrations#new",       as: :signup
  post   "signup",          to: "registrations#create"
  get    "change_password", to: "change_password#edit",    as: :change_password
  patch  "change_password", to: "change_password#update"

  get    "approvals/:token",        to: "approvals#show",   as: :approval
  post   "approvals/:token/approve", to: "approvals#approve", as: :approve_approval
  post   "approvals/:token/refuse",  to: "approvals#refuse",  as: :refuse_approval

  get  "commande/:token/confirmation", to: "order_receptions#show",    as: :order_reception
  post "commande/:token/confirmation", to: "order_receptions#confirm", as: :confirm_order_reception

  get "setup/admin", to: "setup#admin"

  get "bon_de_commande", to: "generic_orders#show"

  root to: redirect("/catalogue.html")

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/emails"
  end

  # Reveal health status on /up that returns 200 if the app boots without exceptions, 404 otherwise.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
