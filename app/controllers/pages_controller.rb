class PagesController < ApplicationController
  add_breadcrumb "Lite Jot", '/'

  def welcome
    @user_sign_up = User.new
    @user_log_in = User.new
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

    if !current_user.meta.saw_last_news_flash
      @show_news_flash = true
      current_user.meta.saw_last_news_flash = true
      current_user.meta.save!
    else
      @show_news_flash = false
    end
  end

  def terms
    add_breadcrumb "Terms of Service"
  end

  def privacy
    add_breadcrumb "Privacy Policy"
  end

  def support
    add_breadcrumb "Support Center"
  end

end
