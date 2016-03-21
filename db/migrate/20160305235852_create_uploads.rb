class CreateUploads < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.integer :user_id, null: false
      t.string :direct_upload_url, null: false
      t.attachment :upload
      t.boolean :processed, default: false, null: false
      t.timestamps
    end
    add_index :uploads, :user_id
    add_index :uploads, :processed
  end
end
