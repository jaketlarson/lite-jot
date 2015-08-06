class CreateShares < ActiveRecord::Migration
  def change
    create_table :shares do |t|
      t.integer :folder_id
      t.boolean :is_all_topics
      t.string :specific_topics
      t.integer :recipient_id

      t.timestamps
    end
  end
end
