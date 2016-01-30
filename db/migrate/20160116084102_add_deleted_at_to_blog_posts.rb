class AddDeletedAtToBlogPosts < ActiveRecord::Migration
  def change
    add_column :blog_posts, :deleted_at, :datetime
    add_index :blog_posts, :deleted_at
  end
end
