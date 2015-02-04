class CreateJots < ActiveRecord::Migration
  def change
    create_table :jots do |t|
      t.integer :folder_id
      t.integer :topic_id
      t.integer :user_id
      t.boolean :is_highlighted
      t.integer :order
      t.text :content

      t.timestamps
    end
  end
end
