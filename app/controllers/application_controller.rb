class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :switch_locale

  protected

  def switch_locale
    locale = params[:locale] || cookies[:locale] || I18n.default_locale
    I18n.locale = locale.to_sym if I18n.available_locales.include?(locale.to_sym)
    cookies[:locale] = { value: I18n.locale, expires: 1.year.from_now }
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email])
    devise_parameter_sanitizer.permit(:account_update, keys: [:email])
  end

  def after_sign_in_path_for(resource)
    dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end
