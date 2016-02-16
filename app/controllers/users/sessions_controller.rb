class Users::SessionsController < Devise::SessionsController
  add_breadcrumb 'Lite Jot', '/'

  # GET /resource/sign_in
  def new
    @user_log_in = User.new
    session['omniauth_error_return'] = 'log_in'

    # self.resource = resource_class.new(sign_in_params)
    # clean_up_passwords(resource)
    # yield resource if block_given?
    # respond_with(resource, serialize_options(resource))

    # if params[:redirect_to].present?
    #   store_location_for(resource, params[:redirect_to])    
    # end
  end

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate!(auth_options)
    #set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    yield if block_given?
    respond_to_on_destroy
  end
end
