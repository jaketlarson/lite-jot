class AddDeletedAtToBlogSubscriptions < ActiveRecord::Migration
  def change
    add_column :blog_subscriptions, :deleted_at, :datetime
    add_index :blog_subscriptions, :deleted_at
  end
end
