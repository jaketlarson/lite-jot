class CreateTopicShares < ActiveRecord::Migration
  def change
    create_table :topic_shares do |t|
      t.integer :sender_id
      t.string :recipient_emai
      t.integer :folder_id
      t.integer :topic_id

      t.timestamps
    end
  end
end
