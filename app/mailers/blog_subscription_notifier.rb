class BlogSubscriptionNotifier < ActionMailer::Base
  layout 'email'
  default :from => Rails.application.secrets.news_email_address

  def send_subscribe_email(subscription)
    @subscription = subscription
    m = mail( :to => @subscription.email,
    :subject => "Thanks for subscribing!" )
    m.transport_encoding = "base64"
    m
  end

  def send_blog_alert_email(subscription, blog_post, email)
    @subscription = subscription
    @blog_post = blog_post
    m = mail( :to => email,
    :subject => @blog_post.title )
    m.transport_encoding = "base64"
    m
  end

  # Keep the view for this email as close to #send_blog_alert_email as possible for testing purposes
  def send_blog_alert_as_test_to_admin_email(subscription, blog_post, email)
    @subscription = subscription
    @blog_post = blog_post
    m = mail( :to => email,
    :subject => "[Admin Test] #{@blog_post.title}" )
    m.transport_encoding = "base64"
    m
  end
end
