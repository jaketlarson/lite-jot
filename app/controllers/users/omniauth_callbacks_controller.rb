class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_filter :authenticate

  # Note about session 'omniauth_error_return'...
  # Since we have a sign in and log in page, with omniauth actions doing the exact
  # same thing, we need to track where to return them to.

  
  def google_oauth2
      # You need to implement the method below in your model (e.g. app/models/user.rb)
      @user = User.find_for_google_oauth2(request.env["omniauth.auth"])

      if @user.persisted?
        #flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Google"
        sign_in_and_redirect @user, :event => :authentication
      else
        session["devise.google_data"] = request.env["omniauth.auth"]

        if !session['omniauth_error_return'].nil? && session['omniauth_error_return'] == 'log_in'
          redirect_to log_in_url
        else
          redirect_to sign_up_url
        end
      end
  end

  def facebook
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.find_for_facebook(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      #set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      if !session['omniauth_error_return'].nil? && session['omniauth_error_return'] == 'log_in'
        redirect_to log_in_url
      else
        redirect_to sign_up_url
      end
    end
  end

  def failure
    set_flash_message :alert, :failure, kind: OmniAuth::Utils.camelize(failed_strategy.name), reason: failure_message
    if !session['omniauth_error_return'].nil? && session['omniauth_error_return'] == 'log_in'
      redirect_to log_in_url
    else
      redirect_to sign_up_url
    end
  end
end
