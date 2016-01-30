class Admin::UsersController < ApplicationController
  before_filter :verify_admin
  layout 'admin/application'
  helper_method :sort_column, :sort_direction
  add_breadcrumb "Admin", :admin_path

  def index
    @users = User.order(sort_column + " " + sort_direction).paginate(:page => params[:page])
    add_breadcrumb "Users", :admin_users_path
  end

  def show
    @user = User.find(params[:id])
    add_breadcrumb "Users", :admin_users_path
    add_breadcrumb "User Details"
  end

  private

  def sort_column
    User.column_names.include?(params[:sort]) ? params[:sort] : "id"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

end
