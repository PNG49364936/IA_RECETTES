class PagesController < ApplicationController
  def home
    # Page d'accueil publique
    redirect_to dashboard_path if user_signed_in?
  end

  def dashboard
    authenticate_user!
    # Dashboard utilisateur après connexion
  end

  def set_locale
    locale = params[:locale]&.to_sym
    if I18n.available_locales.include?(locale)
      cookies[:locale] = { value: locale, expires: 1.year.from_now }
    end
    redirect_back(fallback_location: root_path)
  end
end
