class CustomFailure < Devise::FailureApp
  def redirect_url
    flash[:alert] = "Username and password combination does not match."
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