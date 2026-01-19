Rails.application.routes.draw do
  # Page d'accueil = formulaire de recette
  root 'recipes#new'

  # Routes pour les recettes
  resources :recipes, only: [:new, :create, :show] do
    collection do
      get :download_pdf
    end
  end

  # Health check pour déploiement
  get "up" => "rails/health#show", as: :rails_health_check
end
