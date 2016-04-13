class Admin::PagesController < ApplicationController
  before_filter :verify_admin
  layout 'admin/application'

  def dashboard
  end

  def news_flash
    @num_seen = UserMetaDatum.where('saw_last_news_flash = ?', true).count
    add_breadcrumb "Admin", :admin_path
    add_breadcrumb "News Flash"
  end

  def reset_news_flash
    UserMetaDatum.update_all(:saw_last_news_flash => false)
    redirect_to :admin_news_flash
  end
end
