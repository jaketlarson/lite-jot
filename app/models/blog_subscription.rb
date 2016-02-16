class BlogSubscription < ActiveRecord::Base
  acts_as_paranoid
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  self.per_page = 25

  def self.generate_key
    (0...64).map { (65 + rand(26)).chr }.join
  end

  def self.already_subscribed(email)
    BlogSubscription.where("email = ?", email).count > 0
  end

  def self.previously_unsubscribed(email)
    BlogSubscription.only_deleted.where("email = ?", email).count > 0
  end

  def send_subscribe_email
    BlogSubscriptionNotifier.send_subscribe_email(self).deliver_now
  end

  def send_blog_alert_email(blog_post, email)
    BlogSubscriptionNotifier.send_blog_alert_email(self, blog_post, email).deliver_now
  end

  def self.send_blog_alert_as_test_to_admin_email(blog_post, email)
    BlogSubscriptionNotifier.send_blog_alert_as_test_to_admin_email(self, blog_post, email).deliver_now
  end

  def self.create_sub_for_current_user(email)
    if self.already_subscribed(email)
      # Don't subscribe a user a second time
      return

    elsif self.previously_unsubscribed(email)
      # Case where user was subscribed, then unsubscribed (paranoia gem keeps deleted records)
      old_sub = self.with_deleted.where("email = ?", email)[0]
      old_sub.restore
    else
      new_sub = self.new(:email => email, :unsub_key => self.generate_key)
      new_sub.save!
    end
  end
end
