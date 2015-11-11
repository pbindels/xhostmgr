Hostmgr::Application.routes.draw do
  resources :host_types


  resources :roles


  resources :products


  match 'hosts/do_task' => 'hosts#do_task'

  get "git_hub/authorize"
  get "git_hub/callback"
  post 'hosts/do_task'
  get 'hosts/index'
  get 'hosts/search'

#  get 'hosts/:id/clone' => 'hosts#clone', :as => 'clone_host'
#  get 'hosts/:id/edit_clone' => 'hosts#edit_clone', :as => 'clone'
#  post 'hosts/:id/clone' => 'hosts#clone'
#  put 'hosts/:id/clone' => 'hosts#clone'
#  put 'hosts/:id' => 'hosts#clone'

  resources :hosts
  resources :github

#  match 'hosts/:id/clone' => 'hosts#clone', :as => 'clone_host'
#  match 'hosts/:id/clone' => 'hosts#create', :as => 'clone_host'
#  get 'hosts/clone'
  post 'hosts/new'
  post 'hosts/create'


#  post 'hosts/search' => 'hosts#search', :as => 'Search'
#  post 'hosts/clone' => 'hosts#create'



  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'
  root :to => 'hosts#index'
  #root :to => 'hosts#new'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
