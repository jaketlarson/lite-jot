class AddUnsubKeyToBlogSubs < ActiveRecord::Migration
  def change
    add_column :blog_subscriptions, :unsub_key, :string
  end
end
