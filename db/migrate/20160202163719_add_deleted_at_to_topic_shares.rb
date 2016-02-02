class AddDeletedAtToTopicShares < ActiveRecord::Migration
  def change
    add_column :topic_shares, :deleted_at, :datetime
    add_index :topic_shares, :deleted_at
  end
end
