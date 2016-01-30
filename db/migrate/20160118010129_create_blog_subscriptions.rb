class CreateBlogSubscriptions < ActiveRecord::Migration
  def change
    create_table :blog_subscriptions do |t|
      t.string :email

      t.timestamps
    end
  end
end
