class AddRestoredAtToJots < ActiveRecord::Migration
  def change
    add_column :jots, :restored_at, :datetime
  end
end
