Rails.application.routes.draw do
  root 'orders#index'
  resources :suppliers
  resources :products
  resources :orders do
    member do
      post :send_to_supplier
      get :download_pdf
    end
    resources :order_lines, only: [:create, :destroy]
  end
end
