class CreateUserMetaData < ActiveRecord::Migration
  def change
    create_table :user_meta_data do |t|
      t.float :upload_size_this_month, :default => 0
      t.datetime :upload_limit_resets_at
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
