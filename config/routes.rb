Rails.application.routes.draw do
  # Devise pour l'authentification
  devise_for :users

  # Page d'accueil publique
  root 'pages#home'

  # Dashboard utilisateur (après connexion)
  get 'dashboard', to: 'pages#dashboard'

  # Administration (réservé à l'admin)
  get 'admin', to: 'admin#index'
  get 'admin/users', to: 'admin#users'
  get 'admin/recipes', to: 'admin#recipes'
  get 'admin/recipe/:id', to: 'admin#show_recipe', as: 'admin_show_recipe'

  # Routes pour les recettes
  resources :recipes, only: [:new, :create, :show, :destroy] do
    member do
      get :download_pdf
    end
    collection do
      post :save
    end
  end

  # Health check pour déploiement
  get "up" => "rails/health#show", as: :rails_health_check
end
