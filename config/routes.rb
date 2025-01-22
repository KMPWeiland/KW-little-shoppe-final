Rails.application.routes.draw do
 
  get "up" => "rails/health#show", as: :rails_health_check

 
  namespace :api do
    namespace :v1 do
      namespace :items do
        resources :find, only: :index, controller: :search, action: :show
        resources :find_all, only: :index, controller: :search
      end
      resources :items, except: [:new, :edit] do
        get "/merchant", to: "items/merchants#show"
      end
      namespace :merchants do
        resources :find, only: :index, controller: :search, action: :show
        resources :find_all, only: :index, controller: :search
      end
      resources :merchants, except: [:new, :edit] do
        resources :coupons, except: [:destroy], controller: "merchants/coupons" 
        resources :items, only: :index, controller: "merchants/items"
        resources :customers, only: :index, controller: "merchants/customers"
        resources :invoices, only: :index, controller: "merchants/invoices"
      end
    end
  end
end
