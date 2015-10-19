class PagesController < ApplicationController

  def welcome
    @user_sign_up = User.new
    @user_sign_in = User.new
  end

  def getting_started
    @user_sign_up = User.new
    @user_sign_in = User.new
  end

  def dashboard
    @user = current_user

    if !@user.preferences.blank?
      begin
        @jot_size = JSON.parse(@user.preferences)['jot_size'] ? JSON.parse(@user.preferences)['jot_size'] : 1.0
      rescue
        @jot_size = 1.0
      end
    else
      @jot_size = 1.0
    end
  end

  def terms
  end

  def privacy
  end

end
