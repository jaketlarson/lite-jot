class AddDeletedAtToJots < ActiveRecord::Migration
  def change
    add_column :jots, :deleted_at, :datetime
    add_index :jots, :deleted_at
  end
end
