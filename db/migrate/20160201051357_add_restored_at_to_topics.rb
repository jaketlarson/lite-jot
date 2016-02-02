class AddRestoredAtToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :restored_at, :datetime
  end
end
