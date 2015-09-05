Rails.application.routes.draw do

  get 'errors/file_not_found'

  get 'errors/unprocessable'

  get 'errors/internal_server_error'

  devise_for :users, :controllers => {
    :sessions => 'users/sessions',
    :registrations => 'users/registrations',
    :omniauth_callbacks => "users/omniauth_callbacks"
  }, :path_names => {
    :sign_up => 'pages#welcome',
    :sign_in => 'pages#welcome'
  }

  devise_scope :user do
    get '/user/saw-intro' => 'users/registrations#saw_intro'
  end

  authenticated :user do
    root :to => "pages#dashboard", :as => "authenticated_root"
  end

  unauthenticated do
    root :to => "pages#welcome", :as => "unauthenticated_root"
  end

  resources :pages

  resources :folders

  resources :topics

  patch 'jots/flag/:id' => 'jots#flag'
  patch 'jots/check_box/:id' => 'jots#check_box'
  resources :jots

  post 'archived_jots/restore' => 'archived_jots#restore'
  delete 'archived_jots' => 'archived_jots#destroy'
  resources :archived_jots

  resources :shares

  get 'notifications/calendar' => 'notifications#calendar'
  post 'notifications/acknowledge' => 'notifications#acknowledge'
  resources :notifications

  resources :gmail_api

  get '/load-data' => 'application#load_data'
  get '/connection-test' => 'application#connection_test'
  post '/transfer-data' => 'application#transfer_data'
  get 'raw-data' => 'application#raw_data'

  get 'terms' => 'pages#terms'
  get 'privacy' => 'pages#privacy'

  match '/404', :to => 'errors#file_not_found', :via => :all
  match '/422', :to => 'errors#unprocessable', :via => :all
  match '/500', :to => 'errors#internal_server_error', :via => :all
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
