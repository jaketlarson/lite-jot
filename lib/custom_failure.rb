class CustomFailure < Devise::FailureApp
  def redirect_url
    flash[:alert] = "Email and password combination does not match."
    return "/"
  end
  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end