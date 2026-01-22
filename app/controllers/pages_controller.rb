class PagesController < ApplicationController
  def home
    # Page d'accueil publique
    redirect_to dashboard_path if user_signed_in?
  end

  def dashboard
    authenticate_user!
    # Dashboard utilisateur après connexion
  end
end
