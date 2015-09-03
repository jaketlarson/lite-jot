class PagesController < ApplicationController

  def welcome
    @user_sign_up = User.new
    @user_sign_in = User.new
  end

  def dashboard
    @user = current_user
    if params[:send_email] == "true"
      UserNotifier.send_signup_email(@user).deliver
    end
  end

  def terms
  end

  def privacy
  end

end
