class Admin::BlogSubscriptionsController < ApplicationController
  before_filter :verify_admin
  layout 'admin/application'
  helper_method :sort_column, :sort_direction
  add_breadcrumb "Admin", :admin_path

  def index
    add_breadcrumb "Blog Subscriptions", :admin_blog_posts_path
    @blog_subscriptions = BlogSubscription.order("created_at desc").paginate(:page => params[:page])
    # It should be noted that the table on this view uses "updated_at" to show the subscription time.
    # This is referring to the last time they've subscribed, since they can unsubscribe and reactivate
    # their subscription later.
  end

  def destroy
    @blog_subscription = BlogSubscription.find(params[:id])
    @blog_subscription.destroy
 
    redirect_to admin_blog_subscriptions_path
  end

  def send_blog_alert_email
    @blog_post = BlogPost.friendly.find(params[:blog_post_id])

    subscribers = BlogSubscription.all

    subscribers.each do |subscriber|
      subscriber.send_blog_alert_email(@blog_post, subscriber.email)
    end

    @blog_post.subscriber_alert_sent = true
    @blog_post.save
    flash[:notice] = "Blog alert sent to subscribers!"
    redirect_to admin_blog_posts_path
  end

  def send_blog_alert_test_email
    @blog_post = BlogPost.friendly.find(params[:blog_post_id])

    BlogSubscription.send_blog_alert_as_test_to_admin_email(@blog_post, Rails.application.secrets.blog_alert_test_email)

    flash[:notice] = "Blog alert sent to admin test email: #{Rails.application.secrets.blog_alert_test_email}."
    redirect_to admin_blog_posts_path
  end

  private

  def sort_column
    BlogSubscription.column_names.include?(params[:sort]) ? params[:sort] : "id"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

end
