class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include ActionController::Serialization

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) << :username
    devise_parameter_sanitizer.for(:sign_up) << :email
    
    devise_parameter_sanitizer.for(:sign_in) << :username

    devise_parameter_sanitizer.for(:account_update) << :email
    devise_parameter_sanitizer.for(:account_update) << :is_viewing_key_controls
  end

  def sign_up_params
    devise_parameter_sanitizer.sanitize(:sign_up)
  end

  def sign_in_params
    devise_parameter_sanitizer.sanitize(:sign_in)
  end

  def account_update_params
    devise_parameter_sanitizer.sanitize(:account_update)
  end
end
