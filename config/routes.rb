Rails.application.routes.draw do

  mount Bootsy::Engine => '/bootsy', as: 'bootsy'
  devise_for :users, :controllers => {
    :sessions => 'users/sessions',
    :registrations => 'users/registrations',
    :omniauth_callbacks => "users/omniauth_callbacks"
  }

  devise_scope :user do
    get '/log-in' => 'users/sessions#new', :as => 'log_in'
    get '/sign-up' => 'users/registrations#new', :as => 'sign_up'
    get '/user/saw-intro' => 'users/registrations#saw_intro'
    patch '/user/update_preferences' => 'users/registrations#update_preferences'
    get '/reset-password' => 'users/passwords#new', :as => :reset_password
    get '/new-password' => 'users/passwords#edit', :as => :new_password
    post '/send-reset-email' => 'users/passwords#create', :as => :create_password
    put '/change-password' =>  'users/passwords#update', :as => :update_password
    get '/password-reset-success' => 'users/passwords#success', :as => :password_reset_success

    # When submitting a form such as sign up, the user might end up on /users via POST,
    # and if they entered this url via GET they would hit a 404. Patching that...
    get '/users' => 'pages#welcome'
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
  post 'jots/create_email_tag' => 'jots#create_email_tag'
  resources :jots

  post 'archived_jots/restore' => 'archived_jots#restore'
  delete 'archived_jots' => 'archived_jots#destroy'
  resources :archived_jots

  resources :folder_shares

  get 'notifications/calendar' => 'notifications#calendar'
  post 'notifications/acknowledge' => 'notifications#acknowledge'
  resources :notifications

  resources :gmail_api

  get 'admin' => 'admin/pages#dashboard'
  get 'admin/users' => 'admin/users#index'
  get 'admin/users/:id' => 'admin/users#show'

  resources :blog_posts, :only => [:index, :show], :path => 'blog'
  resources :blog_subscriptions, :only => [:create, :destroy]
  get '/blog_subscriptions/unsubscribe/:id/:unsub_key' => 'blog_subscriptions#destroy'
  resources :support_tickets, :only => [:index, :new, :create, :show], :path => 'support-tickets'
  resources :support_ticket_messages, :only => [:create]
  
  #resources :feedback, :only => [:new, :create], :path => "email-support"
  get 'email-support' => 'feedback#new'
  post 'email-support' => 'feedback#create'

  resource :admin do
    resources :blog_posts, :controller => 'admin/blog_posts', :except => [:show], :path => 'blog'
    resources :blog_subscriptions, :controller => 'admin/blog_subscriptions', :only => [:index, :destroy]
    resources :support_tickets, :controller => 'admin/support_tickets', :path => 'support-tickets'
    resources :support_ticket_messages, :controller => 'admin/support_ticket_messages', :only => [:create, :edit, :update, :destroy]
  end

  get 'admin/blog_posts/:blog_post_id/send_blog_alert_email' => 'admin/blog_subscriptions#send_blog_alert_email', :as => 'send_blog_alert_email'
  get 'admin/blog_posts/:blog_post_id/send_blog_alert_test_email' => 'admin/blog_subscriptions#send_blog_alert_test_email', :as => 'send_blog_alert_test_email'

  get '/load-data-init' => 'application#load_data_init'
  get '/load-updates' => 'application#load_updates'
  get '/connection-test' => 'application#connection_test'
  post '/transfer-data' => 'application#transfer_data'

  get 'terms' => 'pages#terms'
  get 'privacy' => 'pages#privacy'
  get 'support' => 'pages#support'

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
