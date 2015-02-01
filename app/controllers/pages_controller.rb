class PagesController < ApplicationController

  def welcome
    @user_sign_up = User.new
    @user_sign_in = User.new
    users = User.all
    users.each do |user|
      puts user.username
    end
  end

  def panel

  end
end
