class MakeBlogsPublicByDefault < ActiveRecord::Migration
  def change
    change_column :blog_posts, :public, :boolean, :default => true
  end
end
