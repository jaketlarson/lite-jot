class UpdateTopicShares < ActiveRecord::Migration
  def change
    add_column :topic_shares, :recipient_id, :integer
    rename_column :topic_shares, :recipient_emai, :recipient_email
  end
end
