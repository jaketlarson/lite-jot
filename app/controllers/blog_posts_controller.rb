class BlogPostsController < ApplicationController
  add_breadcrumb "Lite Jot", '/'
  add_breadcrumb "Blog", :blog_posts_path

  def index
    @blog_posts = BlogPost.where("public = ?", true).order("created_at desc").paginate(:page => params[:page])
  end

  def show
    @blog_post = BlogPost.friendly.find(params[:id])

    if !@blog_post.public? && !current_user.try(:admin?)
      redirect_to blog_posts_path
    else
      if !current_user.try(:admin?)
        @blog_post.hits = @blog_post.hits+1
        @blog_post.save
      end

      @author = User.find(@blog_post.user_id)
      add_breadcrumb ActionView::Base.full_sanitizer.sanitize(@blog_post.title)[0..50].gsub(/\s\w+\s*$/, '...')
    end
  end
end
