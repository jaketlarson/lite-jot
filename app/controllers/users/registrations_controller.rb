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
        respond_with resource, location: unauthenticated_root_url
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      if !resource.errors.empty?
        error_messages = ""
        resource.errors.each do |key, value|
          error_messages += "#{User.human_attribute_name(key)} #{value}<br />"
        end
        set_flash_message :error, error_messages
      end

      @user_sign_up = resource
      @user_sign_in = User.new
      render :template => "/pages/welcome"
    end
  end

  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    if !params[:user].nil? && !params[:user][:password].nil? && params[:user][:password].length > 0 # needs further development
      resource_updated = update_resource_with_password(resource, account_update_params)
    else
      resource_updated = update_resource_without_password(resource, account_update_params)
    end

    yield resource if block_given?
    if resource_updated
      if is_flashing_format?
        flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
          :update_needs_confirmation : :updated
        set_flash_message :success, flash_key
      end
      sign_in resource_name, resource, bypass: true
      render :json => UserSerializer.new(resource, :root => false), :status => :ok
    else
      ap resource
      clean_up_passwords resource
      ap resource
      render :json => UserSerializer.new(resource, :root => false), :status => :not_acceptable
    end


  end

  def saw_intro
    current_user.intro_seen
    render :nothing => true
  end

  def update_preferences
    preferences_param = params[:preferences]

    if preferences_param
      if preferences_param['jot_size'].to_f >= 0.5 && preferences_param['jot_size'].to_f <= 1.5
        current_user.set_preference('jot_size', preferences_param['jot_size'])
      end
    end

    render :nothing => true
  end

  protected

  def update_resource_with_password(resource, params)
    resource.update_with_password(params)
  end

  def update_resource_without_password(resource, params)
    resource.update_without_password(params)
  end
end