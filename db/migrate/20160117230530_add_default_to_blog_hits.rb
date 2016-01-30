class AddDefaultToBlogHits < ActiveRecord::Migration
  def change
    change_column :blog_posts, :hits, :integer, :default => 0
  end
end
