Rails.application.routes.draw do
  resources :suppliers
  resources :products
  resources :chantiers, only: [ :index, :show ]
  get "portail", to: "portail#index", as: :portail
  resources :projets do
    resource :seance_lancement, only: [ :show, :edit, :update ], path: "seance-lancement"
  end
  resources :orders do
    member do
      post :send_to_supplier
      post :resubmit_approval
      get  :download_eml
    end
    resources :order_lines, only: [ :create, :destroy ]
  end
  namespace :api do
    resources :orders, only: [ :create, :index, :destroy ] do
      collection { post :preview_pdf; get :next_number; get :pending_approvals }
      member { patch :confirm_reception; post :resend; post :forward; post :approve; post :refuse; post :cancel; post :relance; get :relance_preview }
    end
    resources :products, only: [ :index ]
    get "hgc_stock/:article", to: "hgc_stock#show", as: :hgc_stock
    resources :devis_imports, only: [ :create ] do
      collection { post :confirm_products; post :equivalent; get :fournisseurs }
    end
    get   "nomenclature",     to: "nomenclature#index"
    patch "nomenclature/:id", to: "nomenclature#update"
    get   "nomenclature_induni", to: "nomenclature_induni#index"
    resources :diesel_prices, only: [ :index, :create ]
    resources :canplast_surcharges, only: [ :index, :create ]
    # Réception de commande / appels de livraison (environnement test uniquement)
    scope :reception, as: :reception do
      get    "orders",                         to: "receptions#orders",            as: :orders
      get    "orders/:id",                     to: "receptions#order",             as: :order
      patch  "orders/:id",                     to: "receptions#update_order",      as: :update_order
      post   "orders/:id/delivery_calls",      to: "receptions#create_call",       as: :create_call
      patch  "delivery_calls/:id",             to: "receptions#update_call",       as: :update_call
      post   "orders/:id/receptions",          to: "receptions#create_reception",  as: :create_reception
      post   "receptions/:id/scans",           to: "receptions#add_scans",         as: :add_scans
      get    "receptions/:id/scans/:scan_id",  to: "receptions#scan",              as: :scan
      delete "receptions/:id",                 to: "receptions#destroy_reception", as: :destroy_reception
    end
    get :me, to: "sessions#me"
    post   "test_profile", to: "test_profiles#create"
    delete "test_profile", to: "test_profiles#destroy"
    post   "push_subscriptions", to: "push_subscriptions#create"
    delete "push_subscriptions", to: "push_subscriptions#destroy"
  end

  namespace :admin do
    resources :users, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      member { post :resend_welcome }
      collection { get :chantier_matches }
    end
    resources :chantiers, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :suppliers, only: [ :index, :edit, :update ]
    resources :orders, only: [ :index ] do
      collection { get :export; delete :purge }
    end
    resources :products, only: [ :index ] do
      collection { get :export }
    end
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
