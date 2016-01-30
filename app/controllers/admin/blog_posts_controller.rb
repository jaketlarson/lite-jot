class Admin::BlogPostsController < ApplicationController
  before_filter :verify_admin
  layout 'admin/application'
  add_breadcrumb "Admin", :admin_path

  def index
    add_breadcrumb "Blog Posts", :admin_blog_posts_path
    @blog_posts = BlogPost.order("created_at desc").paginate(:page => params[:page])
  end

  def new
    @blog_post = BlogPost.new
    add_breadcrumb "Blog Posts", :admin_blog_posts_path
    add_breadcrumb "New"
  end

  def create
    @blog_post = BlogPost.new(blog_post_params[:blog_post])
    @blog_post.user_id = current_user.id

    if @blog_post.save
      redirect_to :admin_blog_posts
    else
      add_breadcrumb "Blog Posts", :admin_blog_posts_path
      add_breadcrumb "New"
      render 'new'
    end
  end

  def edit
    add_breadcrumb "Blog Posts", :admin_blog_posts_path
    add_breadcrumb "Edit"
    @blog_post = BlogPost.friendly.find(params[:id])
  end

  def update
    @blog_post = BlogPost.friendly.find(params[:id])
 
    if @blog_post.update(blog_post_params[:blog_post])
      redirect_to admin_blog_posts_path
    else 
      add_breadcrumb "Blog Posts", :admin_blog_posts_path
      add_breadcrumb "Edit"
      render 'edit'
    end
  end

  def destroy
    @blog_post = BlogPost.find(params[:id])
    @blog_post.destroy
 
    redirect_to admin_blog_posts_path
  end

  protected

    def blog_post_params
      params.permit(:blog_post => [:title, :body, :bootsy_image_gallery_id, :public, :tags])
    end
end
