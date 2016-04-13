class AddSawLastNewsFlashToUserMetaData < ActiveRecord::Migration
  def change
    add_column :user_meta_data, :saw_last_news_flash, :boolean, :default => true
  end
end
