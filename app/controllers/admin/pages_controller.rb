class Admin::PagesController < ApplicationController
  before_filter :verify_admin
  layout 'admin/application'

  def dashboard
  end
end
