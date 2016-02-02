class BlogSubscriptionsController < ApplicationController
  def create
    @blog_subscription = BlogSubscription.new(blog_subscription_params)
    @blog_subscription.unsub_key = BlogSubscription.generate_key
    already_subscribed = BlogSubscription.already_subscribed(params[:email])
    previously_unsubscribed = BlogSubscription.previously_unsubscribed(params[:email])
    
    # Using paranoia gem for this model, so we must check to see if the email is
    # already logged and if so just restore it.
    # Using paranoia allows better tracking of issues with subscriptions as well
    # as mimicking the unsubscribe URL using past emails from Lite Jot, for the
    # sake of consistency. It is not entirely necessary, but that's how it's set
    # up for now.

    unless already_subscribed
      if previously_unsubscribed
        old_sub = BlogSubscription.with_deleted.where("email = ?", params[:email])[0]
        old_sub.restore
        old_sub.send_subscribe_email
        render :json => {:success => true}
      else
        if @blog_subscription.save
          @blog_subscription.send_subscribe_email

          render :json => {:success => true}
        else
          render :json => {:success => false, :error => "Please enter a valid email address"}, :status => :bad_request
        end
      end
    else
      render :json => {:success => false, :error => "You've already subscribed, but we appreciate the enthusiasm!"}, :status => :bad_request
    end
  end

  def destroy
    @blog_subscription = BlogSubscription.where("id = ?", params[:id])

    if @blog_subscription.count == 0 || @blog_subscription[0].unsub_key != params[:unsub_key]
      redirect_to blog_posts_path
    else
      @blog_subscription[0].destroy
      @blog_subscription = @blog_subscription[0]
      render "blog_subscriptions/unsubscribed"
    end
  end

  protected

    def blog_subscription_params
      params.permit(:email)
    end
end
