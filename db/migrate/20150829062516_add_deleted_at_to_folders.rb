class AddDeletedAtToFolders < ActiveRecord::Migration
  def change
    add_column :folders, :deleted_at, :datetime
    add_index :folders, :deleted_at
  end
end
