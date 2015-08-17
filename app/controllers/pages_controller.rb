class PagesController < ApplicationController

  def welcome
    @user_sign_up = User.new
    @user_sign_in = User.new
  end

  def panel
    @user = current_user
  end

  def terms
  end

  def privacy
  end

end
