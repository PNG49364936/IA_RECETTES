Rails.application.routes.draw do
  # Devise pour l'authentification
  devise_for :users

  # Page d'accueil publique
  root 'pages#home'

  # Dashboard utilisateur (après connexion)
  get 'dashboard', to: 'pages#dashboard'

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
