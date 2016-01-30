class AddBlogAlertSent < ActiveRecord::Migration
  def change
    add_column :blog_posts, :subscriber_alert_sent, :boolean, :default => false
  end
end
