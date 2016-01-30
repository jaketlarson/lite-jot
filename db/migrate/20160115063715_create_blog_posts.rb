class CreateBlogPosts < ActiveRecord::Migration
  def change
    create_table :blog_posts do |t|
      t.string :title
      t.text :body
      t.text :tags
      t.integer :hits
      t.boolean :public
      t.integer :user_id

      t.timestamps
    end
  end
end
