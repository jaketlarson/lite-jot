class AddNotificationsSeenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :notifications_seen, :text
  end
end
