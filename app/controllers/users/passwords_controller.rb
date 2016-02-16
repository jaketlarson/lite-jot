class Users::PasswordsController < Devise::PasswordsController
  prepend_before_action :require_no_authentication, :except => :success
  # Render the #edit only if coming from a reset password email link
  append_before_action :assert_reset_token_passed, only: :edit

  # GET /resource/password/new
  def new
    self.resource = resource_class.new
  end

  # POST /resource/password
  def create
    #self.resource = resource_class.send_reset_password_instructions(resource_params)

    self.resource = User.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      render :template => "/users/passwords/email_sent"
      #respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      flash.now[:alert] = "Invalid email address provided"
      render :template => "/users/passwords/new"
      #respond_with(resource)
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    self.resource = resource_class.new
    set_minimum_password_length
    resource.reset_password_token = params[:reset_password_token]

    # So, what happens is we capture the reset_password_token value in params.
    # Then we digest it, see if it is equal to any user in the database, and if
    # not, we send them away. If so, we let them change their password.
    original_token = params[:reset_password_token]
    reset_password_token = Devise.token_generator.digest(self, :reset_password_token, original_token)
    self.resource = resource_class.find_or_initialize_with_error_by(:reset_password_token, reset_password_token)

    if !resource.errors.nil? && !resource.errors.empty?
      flash[:alert] = "Password reset link is invalid or may have expired. Please try resending passwords reset instructions."
      redirect_to reset_password_path
    else
      # put original token back so we don't use the "digested" token:
      self.resource.reset_password_token = original_token
    end
  end

  # PUT /resource/password
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)

    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      if Devise.sign_in_after_reset_password
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message(:notice, flash_message)
        sign_in(resource_name, resource)
      else
        set_flash_message(:notice, :updated_not_active)
      end
      redirect_to password_reset_success_path
    else
      set_minimum_password_length
      respond_with resource
    end
  end

  def success
  end

  protected

    # The path used after sending reset password instructions
    def after_sending_reset_password_instructions_path_for(resource_name)
      new_session_path(resource_name) if is_navigational_format?
    end

    # Check if a reset_password_token is provided in the request
    def assert_reset_token_passed
      if params[:reset_password_token].blank?
        set_flash_message(:alert, :no_token)
        redirect_to new_session_path(resource_name)
      end
    end

    # Check if proper Lockable module methods are present & unlock strategy
    # allows to unlock resource on password reset
    def unlockable?(resource)
      resource.respond_to?(:unlock_access!) &&
        resource.respond_to?(:unlock_strategy_enabled?) &&
        resource.unlock_strategy_enabled?(:email)
    end

    def translation_scope
      'devise.passwords'
    end
end
