class AddRestoredAtToFolders < ActiveRecord::Migration
  def change
    add_column :folders, :restored_at, :datetime
  end
end
