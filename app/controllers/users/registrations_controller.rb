class Users::RegistrationsController < Devise::RegistrationsController
  before_filter :configure_permitted_parameters

  def create
    build_resource(sign_up_params)


    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, location: root_path
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      if !resource.errors.empty?
        error_messages = ""
        resource.errors.each do |key, value|
          error_messages += "#{key.capitalize} #{value}<br />"
        end
        set_flash_message :error, error_messages
      end

      
      @user_sign_up = resource
      @user_sign_in = User.new
      render :template => "/pages/welcome"
    end
  end
end
