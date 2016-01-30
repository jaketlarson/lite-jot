class BlogSubscription < ActiveRecord::Base
  acts_as_paranoid
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  after_create :send_subscribe_email
  self.per_page = 25

  def self.already_subscribed(email)
    BlogSubscription.where("email = ?", email).count > 0
  end

  def self.previously_unsubscribed(email)
    BlogSubscription.only_deleted.where("email = ?", email).count > 0
  end

  def send_subscribe_email
    BlogSubscriptionNotifier.send_subscribe_email(self).deliver
  end

  def send_blog_alert_email(blog_post, email)
    BlogSubscriptionNotifier.send_blog_alert_email(self, blog_post, email).deliver
  end

  def self.send_blog_alert_as_test_to_admin_email(blog_post, email)
    BlogSubscriptionNotifier.send_blog_alert_as_test_to_admin_email(self, blog_post, email).deliver
  end
end
